package io.rynbridge.securestorage

import android.content.Context
import io.rynbridge.core.*

class SecureStorageModule(provider: SecureStorageProvider) : BridgeModule {
    constructor(context: Context) : this(DefaultSecureStorageProvider(context))

    override val name = "secure-storage"
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
        "has" to { payload ->
            val key = payload["key"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: key")
            val exists = provider.has(key)
            mapOf("exists" to BridgeValue.bool(exists))
        }
    )
}
