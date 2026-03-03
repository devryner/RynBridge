package io.rynbridge.storage

import io.rynbridge.core.*

class StorageModule(provider: StorageProvider) : BridgeModule {

    override val name = "storage"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "get" to { payload ->
            val key = payload["key"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: key")
            val value = provider.get(key)
            if (value != null) {
                mapOf("value" to BridgeValue.string(value))
            } else {
                mapOf("value" to BridgeValue.nullValue())
            }
        },
        "set" to { payload ->
            val key = payload["key"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: key")
            val value = payload["value"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: value")
            provider.set(key, value)
            emptyMap()
        },
        "remove" to { payload ->
            val key = payload["key"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: key")
            provider.remove(key)
            emptyMap()
        },
        "clear" to { _ ->
            provider.clear()
            emptyMap()
        },
        "keys" to { _ ->
            val allKeys = provider.keys()
            mapOf("keys" to BridgeValue.array(allKeys.map { BridgeValue.string(it) }))
        }
    )
}
