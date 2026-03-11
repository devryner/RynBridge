package io.rynbridge.push.fcm

import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await

/**
 * Firebase Cloud Messaging provider for FCM-specific operations.
 *
 * This provider handles FCM-specific functionality such as topic subscription,
 * token management, and auto-init configuration.
 *
 * For token refresh events, call [emitTokenRefresh] from your FirebaseMessagingService's
 * onNewToken callback to notify the bridge.
 *
 * @param onTokenRefresh Optional callback to emit token refresh events via the bridge.
 *        Signature: (module: String, action: String, payload: Map) -> Unit
 */
class FirebasePushFCMProvider(
    private val onTokenRefresh: ((String, String, Map<String, io.rynbridge.core.BridgeValue>) -> Unit)? = null
) : PushFCMProvider {

    override suspend fun getToken(): String {
        return FirebaseMessaging.getInstance().token.await()
    }

    override suspend fun deleteToken() {
        FirebaseMessaging.getInstance().deleteToken().await()
    }

    override suspend fun subscribeToTopic(topic: String) {
        FirebaseMessaging.getInstance().subscribeToTopic(topic).await()
    }

    override suspend fun unsubscribeFromTopic(topic: String) {
        FirebaseMessaging.getInstance().unsubscribeFromTopic(topic).await()
    }

    override suspend fun getAutoInitEnabled(): Boolean {
        return FirebaseMessaging.getInstance().isAutoInitEnabled
    }

    override suspend fun setAutoInitEnabled(enabled: Boolean) {
        FirebaseMessaging.getInstance().isAutoInitEnabled = enabled
    }

    /**
     * Call this from FirebaseMessagingService.onNewToken() to emit
     * a token refresh event through the bridge.
     */
    fun emitTokenRefresh(token: String) {
        onTokenRefresh?.invoke(
            "push-fcm",
            "tokenRefresh",
            mapOf("token" to io.rynbridge.core.BridgeValue.string(token))
        )
    }
}
