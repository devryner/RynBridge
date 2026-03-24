package com.devryner.rynbridge.core

import kotlinx.serialization.Serializable

@Serializable
data class BridgeRequest(
    val id: String,
    val module: String,
    val action: String,
    @Serializable(with = BridgeValueMapSerializer::class)
    val payload: Map<String, BridgeValue> = emptyMap(),
    val version: String
)

@Serializable
data class BridgeResponse(
    val id: String,
    val status: ResponseStatus,
    @Serializable(with = BridgeValueMapSerializer::class)
    val payload: Map<String, BridgeValue> = emptyMap(),
    val error: BridgeErrorData? = null
)

@Serializable
enum class ResponseStatus {
    success,
    error
}

@Serializable
data class BridgeErrorData(
    val code: String,
    val message: String,
    @Serializable(with = BridgeValueMapSerializer::class)
    val details: Map<String, BridgeValue>? = null
)

data class BridgeConfig(
    val timeout: Long = 30_000L,
    val version: String = "0.1.0"
) {
    companion object {
        val DEFAULT = BridgeConfig()
    }
}

typealias ActionHandler = suspend (Map<String, BridgeValue>) -> Map<String, BridgeValue>

interface BridgeModule {
    val name: String
    val version: String
    val actions: Map<String, ActionHandler>
}

sealed class IncomingMessage {
    data class Request(val request: BridgeRequest) : IncomingMessage()
    data class Response(val response: BridgeResponse) : IncomingMessage()
}
