package io.rynbridge.analytics

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class AnalyticsModuleTest {

    @Test
    fun `logEvent calls provider with name and params`() = runTest {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        val handler = module.actions["logEvent"]!!

        val result = handler(mapOf(
            "name" to BridgeValue.string("button_click"),
            "params" to BridgeValue.dict(mapOf(
                "screen" to BridgeValue.string("home"),
                "count" to BridgeValue.int(5)
            ))
        ))
        assertTrue(result.isEmpty())
        assertEquals("button_click", provider.lastEventName)
        assertEquals("home", provider.lastEventParams?.get("screen")?.stringValue)
    }

    @Test
    fun `setUserProperty calls provider`() = runTest {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        val handler = module.actions["setUserProperty"]!!

        val result = handler(mapOf(
            "key" to BridgeValue.string("plan"),
            "value" to BridgeValue.string("premium")
        ))
        assertTrue(result.isEmpty())
        assertEquals("plan", provider.lastPropertyKey)
        assertEquals("premium", provider.lastPropertyValue)
    }

    @Test
    fun `setUserId calls provider`() = runTest {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        val handler = module.actions["setUserId"]!!

        val result = handler(mapOf("userId" to BridgeValue.string("user-123")))
        assertTrue(result.isEmpty())
        assertEquals("user-123", provider.lastUserId)
    }

    @Test
    fun `setScreen calls provider`() = runTest {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        val handler = module.actions["setScreen"]!!

        val result = handler(mapOf("name" to BridgeValue.string("home")))
        assertTrue(result.isEmpty())
        assertEquals("home", provider.lastScreenName)
    }

    @Test
    fun `resetUser calls provider`() = runTest {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        val handler = module.actions["resetUser"]!!

        val result = handler(emptyMap())
        assertTrue(result.isEmpty())
        assertTrue(provider.resetUserCalled)
    }

    @Test
    fun `setEnabled returns enabled state`() = runTest {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        val handler = module.actions["setEnabled"]!!

        val result = handler(mapOf("enabled" to BridgeValue.bool(true)))
        assertEquals(true, result["enabled"]?.boolValue)
        assertEquals(true, provider.enabled)
    }

    @Test
    fun `isEnabled returns current state`() = runTest {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        val handler = module.actions["isEnabled"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["enabled"]?.boolValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockAnalyticsProvider()
        val module = AnalyticsModule(provider)
        assertEquals("analytics", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockAnalyticsProvider : AnalyticsProvider {
    var lastEventName: String? = null
    var lastEventParams: Map<String, BridgeValue>? = null
    var lastPropertyKey: String? = null
    var lastPropertyValue: String? = null
    var lastUserId: String? = null
    var lastScreenName: String? = null
    var resetUserCalled = false
    var enabled = true

    override fun logEvent(name: String, params: Map<String, BridgeValue>) {
        lastEventName = name
        lastEventParams = params
    }

    override fun setUserProperty(key: String, value: String) {
        lastPropertyKey = key
        lastPropertyValue = value
    }

    override fun setUserId(userId: String) {
        lastUserId = userId
    }

    override fun setScreen(name: String) {
        lastScreenName = name
    }

    override fun resetUser() {
        resetUserCalled = true
    }

    override suspend fun setEnabled(enabled: Boolean): Boolean {
        this.enabled = enabled
        return enabled
    }

    override suspend fun isEnabled(): Boolean = enabled
}
