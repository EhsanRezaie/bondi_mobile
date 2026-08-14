package ir.bondi.app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun onResume() {
        super.onResume()
        FcmNotificationService.isAppInForeground = true
    }

    override fun onPause() {
        super.onPause()
        FcmNotificationService.isAppInForeground = false
    }
}
