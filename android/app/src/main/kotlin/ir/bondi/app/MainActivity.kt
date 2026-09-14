package ir.bondi.app

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.view.WindowManager
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts a MethodChannel that implements Android's SMS User Consent API so the
 * OTP screen can offer "Allow app to read this SMS?" autofill without holding
 * the RECEIVE_SMS permission.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "ir.bondi.app/sms_consent"
    private val consentRequestCode = 64206
    private var channel: MethodChannel? = null
    private var receiverRegistered = false

    private val smsReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (SmsRetriever.SMS_RETRIEVED_ACTION != intent.action) return
            val extras = intent.extras ?: return
            val status = extras.get(SmsRetriever.EXTRA_STATUS) as? Status ?: return
            when (status.statusCode) {
                CommonStatusCodes.SUCCESS -> {
                    @Suppress("DEPRECATION")
                    val consentIntent =
                        extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                    if (consentIntent != null) {
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(consentIntent, consentRequestCode)
                        } catch (e: Exception) {
                            channel?.invokeMethod("onSmsError", e.message)
                        }
                    }
                }
                CommonStatusCodes.TIMEOUT -> channel?.invokeMethod("onSmsError", "timeout")
            }
            unregisterSmsReceiver()
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    startSmsConsent()
                    result.success(null)
                }
                "stopListening" -> {
                    unregisterSmsReceiver()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startSmsConsent() {
        SmsRetriever.getClient(this)
            .startSmsUserConsent(null)
            .addOnFailureListener { e -> channel?.invokeMethod("onSmsError", e.message) }

        if (!receiverRegistered) {
            val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
            ContextCompat.registerReceiver(
                this,
                smsReceiver,
                filter,
                ContextCompat.RECEIVER_EXPORTED,
            )
            receiverRegistered = true
        }
    }

    private fun unregisterSmsReceiver() {
        if (receiverRegistered) {
            try {
                unregisterReceiver(smsReceiver)
            } catch (_: Exception) {
            }
            receiverRegistered = false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == consentRequestCode) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                channel?.invokeMethod(
                    "onSmsReceived",
                    data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE),
                )
            } else {
                channel?.invokeMethod("onSmsError", "consent_denied")
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        unregisterSmsReceiver()
        super.onDestroy()
    }
}
