package com.devryner.rynbridge.core

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class MessageSerializer(private val version: String = "0.1.0") {

    private val json = Json { encodeDefaults = true }

    fun createRequest(
        module: String,
        action: String,
        payload: Map<String, BridgeValue> = emptyMap()
    ): BridgeRequest {
        return BridgeRequest(
            id = UUID.randomUUID().toString().lowercase(),
            module = module,
            action = action,
            payload = payload,
            version = version
        )
    }

    fun createResponse(
        id: String,
        status: ResponseStatus,
        payload: Map<String, BridgeValue> = emptyMap(),
        error: BridgeErrorData? = null
    ): BridgeResponse {
        return BridgeResponse(id = id, status = status, payload = payload, error = error)
    }

    fun serialize(request: BridgeRequest): String {
        try {
            return json.encodeToString(request)
        } catch (e: RynBridgeError) {
            throw e
        } catch (e: Exception) {
            throw RynBridgeError(
                code = ErrorCode.SERIALIZATION_ERROR,
                message = "Failed to serialize request: ${e.message}"
            )
        }
    }

    fun serialize(response: BridgeResponse): String {
        try {
            return json.encodeToString(response)
        } catch (e: RynBridgeError) {
            throw e
        } catch (e: Exception) {
            throw RynBridgeError(
                code = ErrorCode.SERIALIZATION_ERROR,
                message = "Failed to serialize response: ${e.message}"
            )
        }
    }
}
