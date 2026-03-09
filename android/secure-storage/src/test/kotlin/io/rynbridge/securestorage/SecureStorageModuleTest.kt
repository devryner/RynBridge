package io.rynbridge.securestorage

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class SecureStorageModuleTest {

    @Test
    fun `set and get`() = runTest {
        val provider = MockSecureStorageProvider()
        val module = SecureStorageModule(provider)

        module.actions["set"]!!(mapOf("key" to BridgeValue.string("token"), "value" to BridgeValue.string("abc123")))
        val result = module.actions["get"]!!(mapOf("key" to BridgeValue.string("token")))
        assertEquals("abc123", result["value"]?.stringValue)
    }

    @Test
    fun `get non-existent key`() = runTest {
        val provider = MockSecureStorageProvider()
        val module = SecureStorageModule(provider)

        val result = module.actions["get"]!!(mapOf("key" to BridgeValue.string("missing")))
        assertTrue(result["value"]?.isNull == true)
    }

    @Test
    fun `remove`() = runTest {
        val provider = MockSecureStorageProvider()
        val module = SecureStorageModule(provider)

        module.actions["set"]!!(mapOf("key" to BridgeValue.string("secret"), "value" to BridgeValue.string("data")))
        module.actions["remove"]!!(mapOf("key" to BridgeValue.string("secret")))
        val result = module.actions["get"]!!(mapOf("key" to BridgeValue.string("secret")))
        assertTrue(result["value"]?.isNull == true)
    }

    @Test
    fun `has`() = runTest {
        val provider = MockSecureStorageProvider()
        val module = SecureStorageModule(provider)

        val before = module.actions["has"]!!(mapOf("key" to BridgeValue.string("token")))
        assertEquals(false, before["exists"]?.boolValue)

        module.actions["set"]!!(mapOf("key" to BridgeValue.string("token"), "value" to BridgeValue.string("secret")))

        val after = module.actions["has"]!!(mapOf("key" to BridgeValue.string("token")))
        assertEquals(true, after["exists"]?.boolValue)
    }

    @Test
    fun `get missing key throws`() = runTest {
        val provider = MockSecureStorageProvider()
        val module = SecureStorageModule(provider)

        val exception = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.runBlocking {
                module.actions["get"]!!(emptyMap())
            }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, exception.code)
    }

    @Test
    fun `set missing value throws`() = runTest {
        val provider = MockSecureStorageProvider()
        val module = SecureStorageModule(provider)

        val exception = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.runBlocking {
                module.actions["set"]!!(mapOf("key" to BridgeValue.string("test")))
            }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, exception.code)
    }

    @Test
    fun `module name and version`() {
        val provider = MockSecureStorageProvider()
        val module = SecureStorageModule(provider)
        assertEquals("secure-storage", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockSecureStorageProvider()
        bridge.register(SecureStorageModule(provider))

        val requestJSON = """{"id":"req-1","module":"secure-storage","action":"set","payload":{"key":"pw","value":"secret"},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)
        transport.awaitSent(1)

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)

        bridge.dispose()
    }
}

private class MockSecureStorageProvider : SecureStorageProvider {
    private val store = mutableMapOf<String, String>()

    override fun get(key: String): String? = store[key]
    override fun set(key: String, value: String) { store[key] = value }
    override fun remove(key: String) { store.remove(key) }
    override fun has(key: String): Boolean = store.containsKey(key)
}
