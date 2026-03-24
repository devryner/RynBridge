package com.devryner.rynbridge.ui

import com.devryner.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class UIModuleTest {

    @Test
    fun `showAlert`() = runTest {
        val provider = MockUIProvider()
        val module = UIModule(provider)
        val handler = module.actions["showAlert"]!!

        val result = handler(mapOf(
            "title" to BridgeValue.string("Hello"),
            "message" to BridgeValue.string("World"),
            "buttonText" to BridgeValue.string("OK")
        ))
        assertTrue(result.isEmpty())
        assertEquals("Hello", provider.lastAlertTitle)
        assertEquals("World", provider.lastAlertMessage)
        assertEquals("OK", provider.lastAlertButtonText)
    }

    @Test
    fun `showAlert defaults`() = runTest {
        val provider = MockUIProvider()
        val module = UIModule(provider)
        val handler = module.actions["showAlert"]!!

        handler(mapOf("title" to BridgeValue.string("T"), "message" to BridgeValue.string("M")))
        assertEquals("OK", provider.lastAlertButtonText)
    }

    @Test
    fun `showConfirm`() = runTest {
        val provider = MockUIProvider()
        provider.confirmResult = true
        val module = UIModule(provider)
        val handler = module.actions["showConfirm"]!!

        val result = handler(mapOf(
            "title" to BridgeValue.string("Delete?"),
            "message" to BridgeValue.string("Are you sure?"),
            "confirmText" to BridgeValue.string("Yes"),
            "cancelText" to BridgeValue.string("No")
        ))
        assertEquals(true, result["confirmed"]?.boolValue)
        assertEquals("Delete?", provider.lastConfirmTitle)
    }

    @Test
    fun `showConfirm defaults`() = runTest {
        val provider = MockUIProvider()
        val module = UIModule(provider)
        val handler = module.actions["showConfirm"]!!

        handler(mapOf("title" to BridgeValue.string("T"), "message" to BridgeValue.string("M")))
        assertEquals("Confirm", provider.lastConfirmConfirmText)
        assertEquals("Cancel", provider.lastConfirmCancelText)
    }

    @Test
    fun `showToast`() = runTest {
        val provider = MockUIProvider()
        val module = UIModule(provider)
        val handler = module.actions["showToast"]!!

        val result = handler(mapOf("message" to BridgeValue.string("Saved!"), "duration" to BridgeValue.double(3.0)))
        assertTrue(result.isEmpty())
        assertEquals("Saved!", provider.lastToastMessage)
        assertEquals(3.0, provider.lastToastDuration)
    }

    @Test
    fun `showToast default duration`() = runTest {
        val provider = MockUIProvider()
        val module = UIModule(provider)
        val handler = module.actions["showToast"]!!

        handler(mapOf("message" to BridgeValue.string("Hi")))
        assertEquals(2.0, provider.lastToastDuration)
    }

    @Test
    fun `showActionSheet`() = runTest {
        val provider = MockUIProvider()
        provider.actionSheetResult = 1
        val module = UIModule(provider)
        val handler = module.actions["showActionSheet"]!!

        val result = handler(mapOf(
            "title" to BridgeValue.string("Choose"),
            "options" to BridgeValue.array(listOf(
                BridgeValue.string("A"),
                BridgeValue.string("B"),
                BridgeValue.string("C")
            ))
        ))
        assertEquals(1L, result["selectedIndex"]?.intValue)
        assertEquals(listOf("A", "B", "C"), provider.lastActionSheetOptions)
    }

    @Test
    fun `setStatusBar`() = runTest {
        val provider = MockUIProvider()
        val module = UIModule(provider)
        val handler = module.actions["setStatusBar"]!!

        val result = handler(mapOf("style" to BridgeValue.string("light"), "hidden" to BridgeValue.bool(true)))
        assertTrue(result.isEmpty())
        assertEquals("light", provider.lastStatusBarStyle)
        assertEquals(true, provider.lastStatusBarHidden)
    }

    @Test
    fun `module name and version`() {
        val provider = MockUIProvider()
        val module = UIModule(provider)
        assertEquals("ui", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockUIProvider()
        bridge.register(UIModule(provider))

        val requestJSON = """{"id":"req-1","module":"ui","action":"showToast","payload":{"message":"Hello"},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)
        transport.awaitSent(1)

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals(ResponseStatus.success, response.status)

        bridge.dispose()
    }
}

private class MockUIProvider : UIProvider {
    var lastAlertTitle: String? = null
    var lastAlertMessage: String? = null
    var lastAlertButtonText: String? = null
    var lastConfirmTitle: String? = null
    var lastConfirmConfirmText: String? = null
    var lastConfirmCancelText: String? = null
    var confirmResult = false
    var lastToastMessage: String? = null
    var lastToastDuration: Double? = null
    var lastActionSheetTitle: String? = null
    var lastActionSheetOptions: List<String>? = null
    var actionSheetResult = 0
    var lastStatusBarStyle: String? = null
    var lastStatusBarHidden: Boolean? = null

    override suspend fun showAlert(title: String, message: String, buttonText: String) {
        lastAlertTitle = title
        lastAlertMessage = message
        lastAlertButtonText = buttonText
    }

    override suspend fun showConfirm(title: String, message: String, confirmText: String, cancelText: String): Boolean {
        lastConfirmTitle = title
        lastConfirmConfirmText = confirmText
        lastConfirmCancelText = cancelText
        return confirmResult
    }

    override fun showToast(message: String, duration: Double) {
        lastToastMessage = message
        lastToastDuration = duration
    }

    override suspend fun showActionSheet(title: String?, options: List<String>): Int {
        lastActionSheetTitle = title
        lastActionSheetOptions = options
        return actionSheetResult
    }

    override suspend fun setStatusBar(style: String?, hidden: Boolean?) {
        lastStatusBarStyle = style
        lastStatusBarHidden = hidden
    }

    override fun showKeyboard() {}
    override fun hideKeyboard() {}
    override suspend fun getKeyboardHeight(): KeyboardInfo = KeyboardInfo(height = 0.0, visible = false)
}
