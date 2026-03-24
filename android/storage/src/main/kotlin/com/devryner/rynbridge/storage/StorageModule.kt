package com.devryner.rynbridge.storage

import com.devryner.rynbridge.core.*

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
        },
        "readFile" to { payload ->
            val path = payload["path"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: path")
            val encoding = payload["encoding"]?.stringValue ?: "utf8"
            val content = provider.readFile(path, encoding)
            mapOf("content" to BridgeValue.string(content))
        },
        "writeFile" to { payload ->
            val path = payload["path"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: path")
            val content = payload["content"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: content")
            val encoding = payload["encoding"]?.stringValue ?: "utf8"
            provider.writeFile(path, content, encoding)
            mapOf("success" to BridgeValue.bool(true))
        },
        "deleteFile" to { payload ->
            val path = payload["path"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: path")
            provider.deleteFile(path)
            mapOf("success" to BridgeValue.bool(true))
        },
        "listDir" to { payload ->
            val path = payload["path"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: path")
            val files = provider.listDir(path)
            mapOf("files" to BridgeValue.array(files.map { BridgeValue.string(it) }))
        },
        "getFileInfo" to { payload ->
            val path = payload["path"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: path")
            val info = provider.getFileInfo(path)
            info.toPayload()
        }
    )
}
