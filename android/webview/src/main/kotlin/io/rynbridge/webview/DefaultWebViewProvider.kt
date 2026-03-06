package io.rynbridge.webview

import android.content.Context
import io.rynbridge.core.BridgeValue
import io.rynbridge.core.ErrorCode
import io.rynbridge.core.RynBridgeError

class DefaultWebViewProvider(private val context: Context) : WebViewProvider {

    override suspend fun open(options: OpenOptions): OpenResult {
        throw RynBridgeError(
            code = ErrorCode.UNKNOWN,
            message = "open requires a custom WebViewProvider implementation with Activity context"
        )
    }

    override suspend fun close(webviewId: String) {
        throw RynBridgeError(
            code = ErrorCode.UNKNOWN,
            message = "close requires a custom WebViewProvider implementation with Activity context"
        )
    }

    override suspend fun sendMessage(targetId: String, data: Map<String, BridgeValue>) {
        throw RynBridgeError(
            code = ErrorCode.UNKNOWN,
            message = "sendMessage requires a custom WebViewProvider implementation"
        )
    }

    override fun postEvent(targetId: String, event: String, data: Map<String, BridgeValue>?) {
        // No-op: requires a custom WebViewProvider implementation
    }

    override suspend fun getWebViews(): GetWebViewsResult {
        return GetWebViewsResult(webviews = emptyList())
    }

    override fun setResult(data: Map<String, BridgeValue>) {
        // No-op: requires a custom WebViewProvider implementation
    }
}
