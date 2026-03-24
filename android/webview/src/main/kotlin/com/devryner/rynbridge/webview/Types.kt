package com.devryner.rynbridge.webview

import com.devryner.rynbridge.core.BridgeValue

data class OpenOptions(
    val url: String,
    val title: String? = null,
    val style: String = "modal",
    val allowedOrigins: List<String> = emptyList()
)

data class OpenResult(
    val webviewId: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "webviewId" to BridgeValue.string(webviewId)
    )
}

data class WebViewInfo(
    val webviewId: String,
    val url: String,
    val title: String? = null
) {
    fun toPayload(): Map<String, BridgeValue> {
        val result = mutableMapOf<String, BridgeValue>(
            "webviewId" to BridgeValue.string(webviewId),
            "url" to BridgeValue.string(url)
        )
        if (title != null) {
            result["title"] = BridgeValue.string(title)
        }
        return result
    }
}

data class GetWebViewsResult(
    val webviews: List<WebViewInfo>
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "webviews" to BridgeValue.array(webviews.map { wv ->
            BridgeValue.dict(wv.toPayload())
        })
    )
}

interface WebViewProvider {
    suspend fun open(options: OpenOptions): OpenResult
    suspend fun close(webviewId: String)
    suspend fun sendMessage(targetId: String, data: Map<String, BridgeValue>)
    fun postEvent(targetId: String, event: String, data: Map<String, BridgeValue>?)
    suspend fun getWebViews(): GetWebViewsResult
    fun setResult(data: Map<String, BridgeValue>)
}
