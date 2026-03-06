package io.rynbridge.webview

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class WebViewModuleTest {

    @Test
    fun `open returns webviewId`() = runTest {
        val provider = MockWebViewProvider()
        val module = WebViewModule(provider)
        val handler = module.actions["open"]!!

        val result = handler(mapOf(
            "url" to BridgeValue.string("https://example.com"),
            "title" to BridgeValue.string("Example"),
            "style" to BridgeValue.string("fullScreen"),
            "allowedOrigins" to BridgeValue.array(listOf(BridgeValue.string("https://example.com")))
        ))
        assertEquals("wv-1", result["webviewId"]?.stringValue)
        assertNotNull(provider.lastOpenOptions)
        assertEquals("https://example.com", provider.lastOpenOptions!!.url)
        assertEquals("Example", provider.lastOpenOptions!!.title)
        assertEquals("fullScreen", provider.lastOpenOptions!!.style)
        assertEquals(listOf("https://example.com"), provider.lastOpenOptions!!.allowedOrigins)
    }

    @Test
    fun `close calls provider`() = runTest {
        val provider = MockWebViewProvider()
        val module = WebViewModule(provider)
        val handler = module.actions["close"]!!

        val result = handler(mapOf("webviewId" to BridgeValue.string("wv-1")))
        assertTrue(result.isEmpty())
        assertEquals("wv-1", provider.lastCloseId)
    }

    @Test
    fun `sendMessage calls provider`() = runTest {
        val provider = MockWebViewProvider()
        val module = WebViewModule(provider)
        val handler = module.actions["sendMessage"]!!

        val data = mapOf("key" to BridgeValue.string("value"))
        val result = handler(mapOf(
            "targetId" to BridgeValue.string("wv-1"),
            "data" to BridgeValue.dict(data)
        ))
        assertTrue(result.isEmpty())
        assertEquals("wv-1", provider.lastSendMessageTargetId)
        assertEquals("value", provider.lastSendMessageData?.get("key")?.stringValue)
    }

    @Test
    fun `postEvent calls provider`() = runTest {
        val provider = MockWebViewProvider()
        val module = WebViewModule(provider)
        val handler = module.actions["postEvent"]!!

        val result = handler(mapOf(
            "targetId" to BridgeValue.string("wv-1"),
            "event" to BridgeValue.string("custom-event"),
            "data" to BridgeValue.dict(mapOf("info" to BridgeValue.string("test")))
        ))
        assertTrue(result.isEmpty())
        assertEquals("wv-1", provider.lastPostEventTargetId)
        assertEquals("custom-event", provider.lastPostEventName)
    }

    @Test
    fun `getWebViews returns list`() = runTest {
        val provider = MockWebViewProvider()
        val module = WebViewModule(provider)
        val handler = module.actions["getWebViews"]!!

        val result = handler(emptyMap())
        val webviews = result["webviews"]?.arrayValue
        assertNotNull(webviews)
        assertEquals(1, webviews!!.size)
        assertEquals("wv-1", webviews[0].dictionaryValue?.get("webviewId")?.stringValue)
        assertEquals("https://example.com", webviews[0].dictionaryValue?.get("url")?.stringValue)
    }

    @Test
    fun `setResult calls provider`() = runTest {
        val provider = MockWebViewProvider()
        val module = WebViewModule(provider)
        val handler = module.actions["setResult"]!!

        val data = mapOf("result" to BridgeValue.string("ok"))
        val result = handler(mapOf("data" to BridgeValue.dict(data)))
        assertTrue(result.isEmpty())
        assertEquals("ok", provider.lastSetResultData?.get("result")?.stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockWebViewProvider()
        val module = WebViewModule(provider)
        assertEquals("webview", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockWebViewProvider : WebViewProvider {
    var lastOpenOptions: OpenOptions? = null
    var lastCloseId: String? = null
    var lastSendMessageTargetId: String? = null
    var lastSendMessageData: Map<String, BridgeValue>? = null
    var lastPostEventTargetId: String? = null
    var lastPostEventName: String? = null
    var lastSetResultData: Map<String, BridgeValue>? = null

    override suspend fun open(options: OpenOptions): OpenResult {
        lastOpenOptions = options
        return OpenResult(webviewId = "wv-1")
    }

    override suspend fun close(webviewId: String) {
        lastCloseId = webviewId
    }

    override suspend fun sendMessage(targetId: String, data: Map<String, BridgeValue>) {
        lastSendMessageTargetId = targetId
        lastSendMessageData = data
    }

    override fun postEvent(targetId: String, event: String, data: Map<String, BridgeValue>?) {
        lastPostEventTargetId = targetId
        lastPostEventName = event
    }

    override suspend fun getWebViews(): GetWebViewsResult =
        GetWebViewsResult(webviews = listOf(WebViewInfo(webviewId = "wv-1", url = "https://example.com", title = "Example")))

    override fun setResult(data: Map<String, BridgeValue>) {
        lastSetResultData = data
    }
}
