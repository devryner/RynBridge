package io.rynbridge.push.fcm

import io.rynbridge.push.*

/**
 * Firebase Cloud Messaging Provider for Android.
 *
 * Requires Firebase Messaging SDK dependency:
 *   implementation("com.google.firebase:firebase-messaging-ktx:24.0.0")
 *
 * Usage:
 *   bridge.register(PushModule(FCMPushProvider()))
 */
class FCMPushProvider : PushProvider {

    override suspend fun register(): PushRegistration {
        // TODO: Implement with Firebase Messaging SDK
        // val token = FirebaseMessaging.getInstance().token.await()
        throw UnsupportedOperationException("FCMPushProvider requires Firebase Messaging SDK. Add 'com.google.firebase:firebase-messaging-ktx' dependency.")
    }

    override suspend fun unregister() {
        // TODO: FirebaseMessaging.getInstance().deleteToken().await()
        throw UnsupportedOperationException("FCMPushProvider requires Firebase Messaging SDK.")
    }

    override suspend fun getToken(): String? {
        throw UnsupportedOperationException("FCMPushProvider requires Firebase Messaging SDK.")
    }

    override suspend fun requestPermission(): Boolean {
        // Android 13+ requires POST_NOTIFICATIONS permission
        throw UnsupportedOperationException("FCMPushProvider requires Firebase Messaging SDK.")
    }

    override suspend fun getPermissionStatus(): PushPermissionStatus {
        throw UnsupportedOperationException("FCMPushProvider requires Firebase Messaging SDK.")
    }

    override suspend fun getInitialNotification(): PushNotificationData? {
        throw UnsupportedOperationException("FCMPushProvider requires Firebase Messaging SDK.")
    }
}
