package com.devryner.rynbridge.push.fcm

import com.devryner.rynbridge.core.BridgeValue

data class FCMToken(
    val token: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "token" to BridgeValue.string(token)
    )
}

data class FCMAutoInit(
    val enabled: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "enabled" to BridgeValue.bool(enabled)
    )
}

interface PushFCMProvider {
    suspend fun getToken(): String
    suspend fun deleteToken()
    suspend fun subscribeToTopic(topic: String)
    suspend fun unsubscribeFromTopic(topic: String)
    suspend fun getAutoInitEnabled(): Boolean
    suspend fun setAutoInitEnabled(enabled: Boolean)
}
