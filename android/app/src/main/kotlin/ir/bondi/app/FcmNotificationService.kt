package ir.bondi.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingStore
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * Renders Bondi pushes as a compact, non-expandable notification: a small
 * circular avatar, the sender's name as the title and a short body line.
 *
 * The backend sends data-only FCM messages (no `notification` block, because
 * `notification.image` makes Android draw a big expandable BigPicture card).
 * Everything needed for the row lives in `message.data`:
 *   - title    (sender name for messages, "It's a match!", announcement title)
 *   - body     ("<name> sent you a message", ...)
 *   - image_url (avatar to show in the circle)
 *   - type / user_id / chat_id / match_id (used for tap navigation)
 *
 * Tapping the row opens MainActivity with the message's id stored by the
 * firebase_messaging plugin store, so the Dart side's `getInitialMessage()` /
 * `onMessageOpenedApp` routes the user to the right screen.
 */
class FcmNotificationService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FcmNotification"
        private const val CHANNEL_ID = "bondi_notifications"
        private const val REQUEST_CODE = 1001

        /** Set by MainActivity so foreground pushes stay in-app (Dart toast) instead of showing a system notification. */
        @Volatile
        var isAppInForeground = false
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        if (data.isEmpty()) return

        val title = data["title"] ?: "Notification"
        val body = data["body"] ?: ""
        val type = data["type"] ?: ""
        val imageUrl = data["image_url"]
        val messageId = message.messageId

        Log.d(TAG, "onMessageReceived type=$type title=$title")

        // Make the message discoverable when its notification is tapped:
        // getInitialMessage()/onMessageOpenedApp resolve the payload by id from
        // the plugin store (the plugin only stores messages with a notification
        // block itself, so data-only ones must be stored here).
        if (messageId != null) {
            try {
                FlutterFirebaseMessagingStore.getInstance().storeFirebaseMessage(message)
            } catch (e: Exception) {
                Log.w(TAG, "store message failed: ${e.message}")
            }
        }

        // In the foreground the Flutter side shows the app-themed toast; posting
        // a system notification too would be duplicated.
        if (isAppInForeground) return

        val pending = buildTapPendingIntent(data, messageId)
        Executors.newSingleThreadExecutor().execute {
            val avatar = imageUrl?.let { loadCircularAvatar(it) }
            postNotification(title, body, avatar, pending, type)
        }
    }

    override fun onNewToken(token: String) {
        // The Dart side re-registers tokens with the backend via onTokenRefresh.
        Log.d(TAG, "onNewToken (Dart registers it)")
    }

    private fun buildTapPendingIntent(data: Map<String, String>, messageId: String?): PendingIntent {
        val extras = Bundle()
        // The plugin looks up the stored message by this key on tap.
        if (messageId != null) extras.putString("google.message_id", messageId)
        for ((k, v) in data) extras.putString(k, v)

        val intent = Intent(this, MainActivity::class.java).putExtras(extras)
        return PendingIntent.getActivity(
            this,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun postNotification(
        title: String,
        body: String,
        avatar: Bitmap?,
        pending: PendingIntent,
        type: String
    ) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createChannel(manager)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pending)

        if (avatar != null) builder.setLargeIcon(avatar)
        Log.d(TAG, "posting notification type=$type title=$title avatar=${avatar != null}")

        try {
            val id = (messageKey(title, body) * 31) and Int.MAX_VALUE
            manager.notify(id, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "notify failed: ${e.message}")
        }
    }

    private fun messageKey(title: String, body: String): Int =
        title.hashCode() * 31 + body.hashCode()

    private fun createChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bondi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Likes, matches and messages"
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun loadCircularAvatar(url: String): Bitmap? = try {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.connectTimeout = 8000
        conn.readTimeout = 8000
        conn.instanceFollowRedirects = true
        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Bondi/1.0)")
        conn.connect()

        val stream: InputStream = conn.inputStream
        val bitmap = BitmapFactory.decodeStream(stream)
        stream.close()
        conn.disconnect()
        bitmap?.let(::downscaleAndCrop)
    } catch (e: Exception) {
        Log.w(TAG, "avatar load failed: ${e.message}")
        null
    }

    private fun downscaleAndCrop(src: Bitmap): Bitmap {
        val target = 128
        val size = src.width.coerceAtMost(src.height)
        val scale = size.coerceAtMost(target).toFloat() / size
        val scaled = Bitmap.createScaledBitmap(
            src,
            (src.width * scale).toInt().coerceAtLeast(1),
            (src.height * scale).toInt().coerceAtLeast(1),
            true
        )
        val dim = scaled.width.coerceAtMost(scaled.height)
        val x = (scaled.width - dim) / 2
        val y = (scaled.height - dim) / 2
        val square = Bitmap.createBitmap(scaled, x, y, dim, dim)
        if (scaled !== src) scaled.recycle()
        return circleCrop(square)
    }

    private fun circleCrop(src: Bitmap): Bitmap {
        val out = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint().apply { isAntiAlias = true }
        canvas.drawCircle(src.width / 2f, src.height / 2f, src.width / 2f, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(src, 0f, 0f, paint)
        if (src !== out) src.recycle()
        return out
    }
}
