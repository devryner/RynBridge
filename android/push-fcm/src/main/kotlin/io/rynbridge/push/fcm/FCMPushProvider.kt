package io.rynbridge.push.fcm

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import io.rynbridge.push.*
import kotlinx.coroutines.tasks.await

/**
 * Firebase Cloud Messaging Provider.
 *
 * Requires:
 * - google-services.json in the app module
 * - com.google.gms.google-services plugin applied to the app module
 *
 * @param context Application context
 */
class FCMPushProvider(
    private val context: Context
) : PushProvider {

    private var initialNotification: PushNotificationData? = null

    /**
     * Call from Activity.onCreate to store the notification that launched the app.
     */
    fun setInitialNotification(notification: PushNotificationData?) {
        initialNotification = notification
    }

    override suspend fun register(): PushRegistration {
        val token = FirebaseMessaging.getInstance().token.await()
        return PushRegistration(token = token, platform = "android")
    }

    override suspend fun unregister() {
        FirebaseMessaging.getInstance().deleteToken().await()
    }

    override suspend fun getToken(): String? {
        return try {
            FirebaseMessaging.getInstance().token.await()
        } catch (_: Exception) {
            null
        }
    }

    override suspend fun requestPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true
        }
        val granted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        return granted
    }

    override suspend fun getPermissionStatus(): PushPermissionStatus {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return PushPermissionStatus(status = "granted")
        }
        val granted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        return PushPermissionStatus(status = if (granted) "granted" else "denied")
    }

    override suspend fun getInitialNotification(): PushNotificationData? {
        return initialNotification
    }
}
