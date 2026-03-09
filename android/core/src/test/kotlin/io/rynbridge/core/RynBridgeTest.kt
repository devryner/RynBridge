package io.rynbridge.core

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class RynBridgeTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun `call sends request and resolves response`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))

        val deferred = async {
            bridge.call("device", "getInfo")
        }

        delay(100)

        val sentMessages = transport.sent
        assertEquals(1, sentMessages.size)

        val request = json.decodeFromString<BridgeRequest>(sentMessages[0])
        assertEquals("device", request.module)
        assertEquals("getInfo", request.action)

        val responseJSON = """{"id":"${request.id}","status":"success","payload":{"platform":"android"},"error":null}"""
        transport.simulateIncoming(responseJSON)

        val result = deferred.await()
        assertEquals("android", result["platform"]?.stringValue)

        bridge.dispose()
    }

    @Test
    fun `call rejects on error response`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))

        val deferred = async {
            try {
                bridge.call("device", "getInfo")
                fail("Expected error")
            } catch (e: RynBridgeError) {
                e
            }
        }

        delay(100)

        val request = json.decodeFromString<BridgeRequest>(transport.sent[0])
        val responseJSON = """{"id":"${request.id}","status":"error","payload":{},"error":{"code":"MODULE_NOT_FOUND","message":"Module not found"}}"""
        transport.simulateIncoming(responseJSON)

        val error = deferred.await()
        assertEquals(ErrorCode.MODULE_NOT_FOUND, error.code)

        bridge.dispose()
    }

    @Test
    fun `send fire and forget`() {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport)

        bridge.send("device", "vibrate", mapOf("pattern" to BridgeValue.array(listOf(BridgeValue.int(100)))))

        assertEquals(1, transport.sent.size)
        bridge.dispose()
    }

    @Test
    fun `incoming request routes to module`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))

        val module = object : BridgeModule {
            override val name = "test"
            override val version = "0.1.0"
            override val actions = mapOf<String, ActionHandler>(
                "greet" to { payload ->
                    val name = payload["name"]?.stringValue ?: "World"
                    mapOf("greeting" to BridgeValue.string("Hello, $name!"))
                }
            )
        }
        bridge.register(module)

        val requestJSON = """{"id":"web-req-1","module":"test","action":"greet","payload":{"name":"Kotlin"},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        // Bridge processes on Dispatchers.Default, need real-time wait
        transport.awaitSent(transport.sent.size + 1)

        assertEquals(1, transport.sent.size)
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("web-req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertEquals("Hello, Kotlin!", response.payload["greeting"]?.stringValue)

        bridge.dispose()
    }

    @Test
    fun `incoming request module not found`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport)

        val requestJSON = """{"id":"web-req-2","module":"missing","action":"doSomething","payload":{},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        // Bridge processes on Dispatchers.Default, need real-time wait
        transport.awaitSent(transport.sent.size + 1)

        assertEquals(1, transport.sent.size)
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals(ResponseStatus.error, response.status)
        assertEquals("MODULE_NOT_FOUND", response.error?.code)

        bridge.dispose()
    }

    @Test
    fun `dispose prevents further calls`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport)

        bridge.dispose()

        val exception = assertThrows(RynBridgeError::class.java) {
            runBlocking { bridge.call("device", "getInfo") }
        }
        assertEquals(ErrorCode.TRANSPORT_ERROR, exception.code)
    }

    @Test
    fun `emitEvent sends request to transport`() {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport)

        bridge.emitEvent("push", "onNotification", mapOf(
            "title" to BridgeValue.string("Hello"),
            "body" to BridgeValue.string("World")
        ))

        assertEquals(1, transport.sent.size)

        val request = json.decodeFromString<BridgeRequest>(transport.sent[0])
        assertEquals("push", request.module)
        assertEquals("onNotification", request.action)
        assertEquals("Hello", request.payload["title"]?.stringValue)
        assertEquals("World", request.payload["body"]?.stringValue)

        bridge.dispose()
    }

    @Test
    fun `emitEvent noop after dispose`() {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport)

        bridge.dispose()
        bridge.emitEvent("push", "onNotification")

        assertEquals(0, transport.sent.size)
    }

    @Test
    fun `emitEvent with empty payload`() {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport)

        bridge.emitEvent("navigation", "onDeepLink")

        assertEquals(1, transport.sent.size)

        val request = json.decodeFromString<BridgeRequest>(transport.sent[0])
        assertEquals("navigation", request.module)
        assertEquals("onDeepLink", request.action)
        assertTrue(request.payload.isEmpty())

        bridge.dispose()
    }

    @Test
    fun `dispose send is noop`() {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport)

        bridge.dispose()
        bridge.send("device", "vibrate")

        assertEquals(0, transport.sent.size)
    }
}
