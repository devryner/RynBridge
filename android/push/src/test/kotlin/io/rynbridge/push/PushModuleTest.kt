package io.rynbridge.push

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class PushModuleTest {

    @Test
    fun `register returns push registration`() = runTest {
        val provider = MockPushProvider()
        val module = PushModule(provider)
        val handler = module.actions["register"]!!

        val result = handler(emptyMap())
        assertEquals("mock-push-token-abc", result["token"]?.stringValue)
        assertEquals("android", result["platform"]?.stringValue)
    }

    @Test
    fun `unregister returns empty`() = runTest {
        val provider = MockPushProvider()
        val module = PushModule(provider)
        val handler = module.actions["unregister"]!!

        val result = handler(emptyMap())
        assertTrue(result.isEmpty())
        assertTrue(provider.unregisterCalled)
    }

    @Test
    fun `getToken returns token`() = runTest {
        val provider = MockPushProvider()
        val module = PushModule(provider)
        val handler = module.actions["getToken"]!!

        val result = handler(emptyMap())
        assertEquals("mock-push-token-abc", result["token"]?.stringValue)
    }

    @Test
    fun `getToken returns null when no token`() = runTest {
        val provider = MockPushProvider()
        provider.tokenOverride = null
        provider.returnNullToken = true
        val module = PushModule(provider)
        val handler = module.actions["getToken"]!!

        val result = handler(emptyMap())
        assertTrue(result["token"]?.isNull == true)
    }

    @Test
    fun `requestPermission returns granted`() = runTest {
        val provider = MockPushProvider()
        val module = PushModule(provider)
        val handler = module.actions["requestPermission"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["granted"]?.boolValue)
    }

    @Test
    fun `getPermissionStatus returns status`() = runTest {
        val provider = MockPushProvider()
        val module = PushModule(provider)
        val handler = module.actions["getPermissionStatus"]!!

        val result = handler(emptyMap())
        assertEquals("granted", result["status"]?.stringValue)
    }

    @Test
    fun `getInitialNotification returns notification data`() = runTest {
        val provider = MockPushProvider()
        val module = PushModule(provider)
        val handler = module.actions["getInitialNotification"]!!

        val result = handler(emptyMap())
        assertEquals("Test Title", result["title"]?.stringValue)
        assertEquals("Test Body", result["body"]?.stringValue)
    }

    @Test
    fun `getInitialNotification returns nulls when no notification`() = runTest {
        val provider = MockPushProvider()
        provider.returnNullNotification = true
        val module = PushModule(provider)
        val handler = module.actions["getInitialNotification"]!!

        val result = handler(emptyMap())
        assertTrue(result["title"]?.isNull == true)
        assertTrue(result["body"]?.isNull == true)
        assertTrue(result["data"]?.isNull == true)
    }

    @Test
    fun `module name and version`() {
        val provider = MockPushProvider()
        val module = PushModule(provider)
        assertEquals("push", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockPushProvider()
        bridge.register(PushModule(provider))

        val requestJSON = """{"id":"req-1","module":"push","action":"getToken","payload":{},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        transport.awaitSent(1)

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertEquals("mock-push-token-abc", response.payload["token"]?.stringValue)

        bridge.dispose()
    }
}

private class MockPushProvider : PushProvider {
    var unregisterCalled = false
    var returnNullToken = false
    var returnNullNotification = false
    var tokenOverride: String? = "mock-push-token-abc"

    override suspend fun register(): PushRegistration {
        return PushRegistration(token = "mock-push-token-abc", platform = "android")
    }

    override suspend fun unregister() {
        unregisterCalled = true
    }

    override suspend fun getToken(): String? {
        return if (returnNullToken) null else (tokenOverride ?: "mock-push-token-abc")
    }

    override suspend fun requestPermission(): Boolean {
        return true
    }

    override suspend fun getPermissionStatus(): PushPermissionStatus {
        return PushPermissionStatus(status = "granted")
    }

    override suspend fun getInitialNotification(): PushNotificationData? {
        return if (returnNullNotification) null
        else PushNotificationData(
            title = "Test Title",
            body = "Test Body",
            data = mapOf("key" to BridgeValue.string("value"))
        )
    }
}
