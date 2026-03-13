package io.rynbridge.share

import android.content.Context
import io.rynbridge.core.*

class ShareModule(provider: ShareProvider) : BridgeModule {
    constructor(context: Context) : this(DefaultShareProvider(context))

    override val name = "share"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "share" to { payload ->
            val text = payload["text"]?.stringValue
            val url = payload["url"]?.stringValue
            val title = payload["title"]?.stringValue
            val success = provider.share(text, url, title)
            ShareResult(success).toPayload()
        },
        "shareFile" to { payload ->
            val filePath = payload["filePath"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: filePath")
            val mimeType = payload["mimeType"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: mimeType")
            val success = provider.shareFile(filePath, mimeType)
            ShareResult(success).toPayload()
        },
        "copyToClipboard" to { payload ->
            val text = payload["text"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: text")
            provider.copyToClipboard(text)
            emptyMap()
        },
        "readClipboard" to { _ ->
            val text = provider.readClipboard()
            ClipboardText(text ?: "").toPayload()
        },
        "canShare" to { _ ->
            val canShare = provider.canShare()
            mapOf("canShare" to BridgeValue.bool(canShare))
        }
    )
}
