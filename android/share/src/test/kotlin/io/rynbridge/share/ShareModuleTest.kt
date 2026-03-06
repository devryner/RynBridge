package io.rynbridge.share

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class ShareModuleTest {

    @Test
    fun `share returns success`() = runTest {
        val provider = MockShareProvider()
        val module = ShareModule(provider)
        val handler = module.actions["share"]!!

        val result = handler(mapOf(
            "text" to BridgeValue.string("Hello"),
            "url" to BridgeValue.string("https://example.com"),
            "title" to BridgeValue.string("Title")
        ))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("Hello", provider.lastShareText)
        assertEquals("https://example.com", provider.lastShareUrl)
        assertEquals("Title", provider.lastShareTitle)
    }

    @Test
    fun `shareFile returns success`() = runTest {
        val provider = MockShareProvider()
        val module = ShareModule(provider)
        val handler = module.actions["shareFile"]!!

        val result = handler(mapOf(
            "filePath" to BridgeValue.string("/path/to/file.pdf"),
            "mimeType" to BridgeValue.string("application/pdf")
        ))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("/path/to/file.pdf", provider.lastFilePath)
        assertEquals("application/pdf", provider.lastMimeType)
    }

    @Test
    fun `copyToClipboard stores text`() = runTest {
        val provider = MockShareProvider()
        val module = ShareModule(provider)
        val handler = module.actions["copyToClipboard"]!!

        val result = handler(mapOf("text" to BridgeValue.string("copied text")))
        assertTrue(result.isEmpty())
        assertEquals("copied text", provider.lastClipboardText)
    }

    @Test
    fun `readClipboard returns text`() = runTest {
        val provider = MockShareProvider()
        val module = ShareModule(provider)
        val handler = module.actions["readClipboard"]!!

        val result = handler(emptyMap())
        assertEquals("clipboard content", result["text"]?.stringValue)
    }

    @Test
    fun `canShare returns true`() = runTest {
        val provider = MockShareProvider()
        val module = ShareModule(provider)
        val handler = module.actions["canShare"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["canShare"]?.boolValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockShareProvider()
        val module = ShareModule(provider)
        assertEquals("share", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockShareProvider : ShareProvider {
    var lastShareText: String? = null
    var lastShareUrl: String? = null
    var lastShareTitle: String? = null
    var lastFilePath: String? = null
    var lastMimeType: String? = null
    var lastClipboardText: String? = null

    override suspend fun share(text: String?, url: String?, title: String?): Boolean {
        lastShareText = text
        lastShareUrl = url
        lastShareTitle = title
        return true
    }

    override suspend fun shareFile(filePath: String, mimeType: String): Boolean {
        lastFilePath = filePath
        lastMimeType = mimeType
        return true
    }

    override suspend fun copyToClipboard(text: String) {
        lastClipboardText = text
    }

    override suspend fun readClipboard(): String? = "clipboard content"

    override suspend fun canShare(): Boolean = true
}
