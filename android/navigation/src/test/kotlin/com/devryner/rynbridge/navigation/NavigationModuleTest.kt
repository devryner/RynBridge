package com.devryner.rynbridge.navigation

import com.devryner.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class NavigationModuleTest {

    @Test
    fun `push navigates to screen`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["push"]!!

        val result = handler(mapOf(
            "screen" to BridgeValue.string("details"),
            "params" to BridgeValue.dict(mapOf("id" to BridgeValue.string("123")))
        ))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("details", provider.lastPushScreen)
    }

    @Test
    fun `pop returns success`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["pop"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["success"]?.boolValue)
    }

    @Test
    fun `popToRoot returns success`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["popToRoot"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["success"]?.boolValue)
    }

    @Test
    fun `present shows screen`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["present"]!!

        val result = handler(mapOf(
            "screen" to BridgeValue.string("modal"),
            "style" to BridgeValue.string("fullScreen")
        ))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("modal", provider.lastPresentScreen)
        assertEquals("fullScreen", provider.lastPresentStyle)
    }

    @Test
    fun `dismiss returns success`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["dismiss"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["success"]?.boolValue)
    }

    @Test
    fun `openURL returns success`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["openURL"]!!

        val result = handler(mapOf("url" to BridgeValue.string("https://example.com")))
        assertEquals(true, result["success"]?.boolValue)
    }

    @Test
    fun `canOpenURL returns result`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["canOpenURL"]!!

        val result = handler(mapOf("url" to BridgeValue.string("https://example.com")))
        assertEquals(true, result["canOpen"]?.boolValue)
    }

    @Test
    fun `getInitialURL returns url`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["getInitialURL"]!!

        val result = handler(emptyMap())
        assertEquals("https://initial.com", result["url"]?.stringValue)
    }

    @Test
    fun `getAppState returns state`() = runTest {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        val handler = module.actions["getAppState"]!!

        val result = handler(emptyMap())
        assertEquals("active", result["state"]?.stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockNavigationProvider()
        val module = NavigationModule(provider)
        assertEquals("navigation", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockNavigationProvider : NavigationProvider {
    var lastPushScreen: String? = null
    var lastPresentScreen: String? = null
    var lastPresentStyle: String? = null

    override suspend fun push(screen: String, params: Map<String, BridgeValue>?): PopResult {
        lastPushScreen = screen
        return PopResult(success = true)
    }

    override suspend fun pop(): PopResult = PopResult(success = true)

    override suspend fun popToRoot(): PopResult = PopResult(success = true)

    override suspend fun present(screen: String, style: String?, params: Map<String, BridgeValue>?): PopResult {
        lastPresentScreen = screen
        lastPresentStyle = style
        return PopResult(success = true)
    }

    override suspend fun dismiss(): PopResult = PopResult(success = true)

    override suspend fun openURL(url: String): OpenURLResult = OpenURLResult(success = true)

    override suspend fun canOpenURL(url: String): CanOpenURLResult = CanOpenURLResult(canOpen = true)

    override suspend fun getInitialURL(): InitialURLResult = InitialURLResult(url = "https://initial.com")

    override suspend fun getAppState(): AppStateResult = AppStateResult(state = "active")
}
