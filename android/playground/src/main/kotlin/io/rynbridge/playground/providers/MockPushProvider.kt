package io.rynbridge.playground.providers

import io.rynbridge.push.*
import java.util.UUID

class MockPushProvider : PushProvider {
    override suspend fun getInitialNotification(): PushNotificationData? {
        return null
    }

    override suspend fun register(): PushRegistration {
        return PushRegistration(
            token = "mock_push_token_${UUID.randomUUID().toString().take(8)}",
            platform = "android"
        )
    }

    override suspend fun unregister() {}

    override suspend fun getToken(): String? {
        return "mock_push_token"
    }

    override suspend fun requestPermission(): Boolean {
        return true
    }

    override suspend fun getPermissionStatus(): PushPermissionStatus {
        return PushPermissionStatus(status = "granted")
    }
}
