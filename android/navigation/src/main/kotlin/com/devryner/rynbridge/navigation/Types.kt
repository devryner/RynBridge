package com.devryner.rynbridge.navigation

import com.devryner.rynbridge.core.BridgeValue

data class PopResult(
    val success: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "success" to BridgeValue.bool(success)
    )
}

data class OpenURLResult(
    val success: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "success" to BridgeValue.bool(success)
    )
}

data class CanOpenURLResult(
    val canOpen: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "canOpen" to BridgeValue.bool(canOpen)
    )
}

data class InitialURLResult(
    val url: String?
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "url" to if (url != null) BridgeValue.string(url) else BridgeValue.nullValue()
    )
}

data class AppStateResult(
    val state: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "state" to BridgeValue.string(state)
    )
}

interface NavigationProvider {
    suspend fun push(screen: String, params: Map<String, BridgeValue>?): PopResult
    suspend fun pop(): PopResult
    suspend fun popToRoot(): PopResult
    suspend fun present(screen: String, style: String?, params: Map<String, BridgeValue>?): PopResult
    suspend fun dismiss(): PopResult
    suspend fun openURL(url: String): OpenURLResult
    suspend fun canOpenURL(url: String): CanOpenURLResult
    suspend fun getInitialURL(): InitialURLResult
    suspend fun getAppState(): AppStateResult
}
