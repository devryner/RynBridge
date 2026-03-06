package io.rynbridge.push

import io.rynbridge.core.BridgeValue

data class PushRegistration(
    val token: String,
    val platform: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "token" to BridgeValue.string(token),
        "platform" to BridgeValue.string(platform)
    )
}

data class PushPermissionStatus(
    val status: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "status" to BridgeValue.string(status)
    )
}

data class PushNotificationData(
    val title: String?,
    val body: String?,
    val data: Map<String, BridgeValue>?
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "title" to (title?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "body" to (body?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "data" to (data?.let { BridgeValue.dict(it) } ?: BridgeValue.nullValue())
    )
}

interface PushProvider {
    suspend fun register(): PushRegistration
    suspend fun unregister()
    suspend fun getToken(): String?
    suspend fun requestPermission(): Boolean
    suspend fun getPermissionStatus(): PushPermissionStatus
    suspend fun getInitialNotification(): PushNotificationData?
}
