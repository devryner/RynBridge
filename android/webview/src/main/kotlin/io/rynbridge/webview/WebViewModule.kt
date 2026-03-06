package io.rynbridge.webview

import io.rynbridge.core.*

class WebViewModule(provider: WebViewProvider) : BridgeModule {

    override val name = "webview"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "open" to { payload ->
            val url = payload["url"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: url")
            val title = payload["title"]?.stringValue
            val style = payload["style"]?.stringValue ?: "modal"
            val allowedOrigins = payload["allowedOrigins"]?.arrayValue
                ?.mapNotNull { it.stringValue }
                ?: emptyList()
            val options = OpenOptions(
                url = url,
                title = title,
                style = style,
                allowedOrigins = allowedOrigins
            )
            val result = provider.open(options)
            result.toPayload()
        },
        "close" to { payload ->
            val webviewId = payload["webviewId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: webviewId")
            provider.close(webviewId)
            emptyMap()
        },
        "sendMessage" to { payload ->
            val targetId = payload["targetId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: targetId")
            val data = payload["data"]?.dictionaryValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: data")
            provider.sendMessage(targetId, data)
            emptyMap()
        },
        "postEvent" to { payload ->
            val targetId = payload["targetId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: targetId")
            val event = payload["event"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: event")
            val data = payload["data"]?.dictionaryValue
            provider.postEvent(targetId, event, data)
            emptyMap()
        },
        "getWebViews" to { _ ->
            val result = provider.getWebViews()
            result.toPayload()
        },
        "setResult" to { payload ->
            val data = payload["data"]?.dictionaryValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: data")
            provider.setResult(data)
            emptyMap()
        }
    )
}
