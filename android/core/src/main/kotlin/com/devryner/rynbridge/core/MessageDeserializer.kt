package com.devryner.rynbridge.core

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class MessageDeserializer {

    private val json = Json { ignoreUnknownKeys = true }

    fun deserialize(raw: String): IncomingMessage {
        val jsonElement = try {
            json.parseToJsonElement(raw)
        } catch (e: Exception) {
            throw RynBridgeError(
                code = ErrorCode.INVALID_MESSAGE,
                message = "Failed to parse JSON: ${e.message}"
            )
        }

        val obj = jsonElement.jsonObject

        val id = obj["id"]?.jsonPrimitive?.content
        if (id.isNullOrEmpty()) {
            throw RynBridgeError(
                code = ErrorCode.INVALID_MESSAGE,
                message = "Message missing required field: id"
            )
        }

        // Discriminate by "status" field: present → response, absent → request
        return if (obj.containsKey("status")) {
            val response = decodeResponse(raw)
            IncomingMessage.Response(response)
        } else {
            val request = decodeRequest(raw)
            IncomingMessage.Request(request)
        }
    }

    private fun decodeRequest(raw: String): BridgeRequest {
        val request = try {
            json.decodeFromString<BridgeRequest>(raw)
        } catch (e: RynBridgeError) {
            throw e
        } catch (e: Exception) {
            throw RynBridgeError(
                code = ErrorCode.INVALID_MESSAGE,
                message = "Failed to decode request: ${e.message}"
            )
        }

        if (request.module.isEmpty()) {
            throw RynBridgeError(
                code = ErrorCode.INVALID_MESSAGE,
                message = "Request missing required field: module"
            )
        }
        if (request.action.isEmpty()) {
            throw RynBridgeError(
                code = ErrorCode.INVALID_MESSAGE,
                message = "Request missing required field: action"
            )
        }

        return request
    }

    private fun decodeResponse(raw: String): BridgeResponse {
        try {
            return json.decodeFromString<BridgeResponse>(raw)
        } catch (e: Exception) {
            throw RynBridgeError(
                code = ErrorCode.INVALID_MESSAGE,
                message = "Failed to decode response: ${e.message}"
            )
        }
    }
}
