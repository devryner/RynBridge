package io.rynbridge.storage

import io.rynbridge.core.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class StorageModuleTest {

    @Test
    fun `set and get`() = runTest {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)

        module.actions["set"]!!(mapOf("key" to BridgeValue.string("name"), "value" to BridgeValue.string("Alice")))
        val result = module.actions["get"]!!(mapOf("key" to BridgeValue.string("name")))
        assertEquals("Alice", result["value"]?.stringValue)
    }

    @Test
    fun `get non-existent key`() = runTest {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)

        val result = module.actions["get"]!!(mapOf("key" to BridgeValue.string("missing")))
        assertTrue(result["value"]?.isNull == true)
    }

    @Test
    fun `remove`() = runTest {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)

        module.actions["set"]!!(mapOf("key" to BridgeValue.string("temp"), "value" to BridgeValue.string("data")))
        module.actions["remove"]!!(mapOf("key" to BridgeValue.string("temp")))
        val result = module.actions["get"]!!(mapOf("key" to BridgeValue.string("temp")))
        assertTrue(result["value"]?.isNull == true)
    }

    @Test
    fun `clear`() = runTest {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)

        module.actions["set"]!!(mapOf("key" to BridgeValue.string("a"), "value" to BridgeValue.string("1")))
        module.actions["set"]!!(mapOf("key" to BridgeValue.string("b"), "value" to BridgeValue.string("2")))
        module.actions["clear"]!!(emptyMap())

        val keysResult = module.actions["keys"]!!(emptyMap())
        val keys = keysResult["keys"]?.arrayValue ?: emptyList()
        assertTrue(keys.isEmpty())
    }

    @Test
    fun `keys`() = runTest {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)

        module.actions["set"]!!(mapOf("key" to BridgeValue.string("x"), "value" to BridgeValue.string("1")))
        module.actions["set"]!!(mapOf("key" to BridgeValue.string("y"), "value" to BridgeValue.string("2")))

        val result = module.actions["keys"]!!(emptyMap())
        val keys = result["keys"]?.arrayValue?.mapNotNull { it.stringValue }?.sorted() ?: emptyList()
        assertEquals(listOf("x", "y"), keys)
    }

    @Test
    fun `get missing key throws`() = runTest {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)

        val exception = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.runBlocking {
                module.actions["get"]!!(emptyMap())
            }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, exception.code)
    }

    @Test
    fun `set missing value throws`() = runTest {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)

        val exception = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.runBlocking {
                module.actions["set"]!!(mapOf("key" to BridgeValue.string("test")))
            }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, exception.code)
    }

    @Test
    fun `module name and version`() {
        val provider = MockStorageProvider()
        val module = StorageModule(provider)
        assertEquals("storage", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockStorageProvider()
        bridge.register(StorageModule(provider))

        val setRequestJSON = """{"id":"req-set","module":"storage","action":"set","payload":{"key":"hello","value":"world"},"version":"0.1.0"}"""
        transport.simulateIncoming(setRequestJSON)
        withContext(Dispatchers.Default) { delay(200) }

        transport.reset()
        val getRequestJSON = """{"id":"req-get","module":"storage","action":"get","payload":{"key":"hello"},"version":"0.1.0"}"""
        transport.simulateIncoming(getRequestJSON)
        withContext(Dispatchers.Default) { delay(200) }

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("world", response.payload["value"]?.stringValue)

        bridge.dispose()
    }
}

private class MockStorageProvider : StorageProvider {
    private val store = mutableMapOf<String, String>()

    override fun get(key: String): String? = store[key]
    override fun set(key: String, value: String) { store[key] = value }
    override fun remove(key: String) { store.remove(key) }
    override fun clear() { store.clear() }
    override fun keys(): List<String> = store.keys.sorted()

    override fun readFile(path: String, encoding: String): String = "mock content"
    override fun writeFile(path: String, content: String, encoding: String) {}
    override fun deleteFile(path: String) {}
    override fun listDir(path: String): List<String> = listOf("file1.txt", "file2.txt")
    override fun getFileInfo(path: String): FileInfo = FileInfo(size = 1024, modifiedAt = "2024-01-15T10:30:00Z", isDirectory = false)
}
