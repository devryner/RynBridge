package io.rynbridge.core

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class MessageDeserializerTest {

    private val deserializer = MessageDeserializer()

    @Test
    fun `deserialize request`() {
        val json = """{"id":"req-1","module":"device","action":"getInfo","payload":{},"version":"0.1.0"}"""
        val message = deserializer.deserialize(json)
        assertTrue(message is IncomingMessage.Request)
        val request = (message as IncomingMessage.Request).request
        assertEquals("req-1", request.id)
        assertEquals("device", request.module)
        assertEquals("getInfo", request.action)
        assertEquals("0.1.0", request.version)
    }

    @Test
    fun `deserialize success response`() {
        val json = """{"id":"res-1","status":"success","payload":{"value":"hello"},"error":null}"""
        val message = deserializer.deserialize(json)
        assertTrue(message is IncomingMessage.Response)
        val response = (message as IncomingMessage.Response).response
        assertEquals("res-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertEquals("hello", response.payload["value"]?.stringValue)
        assertNull(response.error)
    }

    @Test
    fun `deserialize error response`() {
        val json = """{"id":"res-2","status":"error","payload":{},"error":{"code":"TIMEOUT","message":"Request timed out"}}"""
        val message = deserializer.deserialize(json)
        assertTrue(message is IncomingMessage.Response)
        val response = (message as IncomingMessage.Response).response
        assertEquals(ResponseStatus.error, response.status)
        assertEquals("TIMEOUT", response.error?.code)
        assertEquals("Request timed out", response.error?.message)
    }

    @Test
    fun `deserialize invalid JSON`() {
        val exception = assertThrows(RynBridgeError::class.java) {
            deserializer.deserialize("not json")
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, exception.code)
    }

    @Test
    fun `deserialize missing ID`() {
        val json = """{"module":"device","action":"getInfo","payload":{},"version":"0.1.0"}"""
        val exception = assertThrows(RynBridgeError::class.java) {
            deserializer.deserialize(json)
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, exception.code)
    }

    @Test
    fun `deserialize missing module`() {
        val json = """{"id":"req-1","action":"getInfo","payload":{},"version":"0.1.0"}"""
        val exception = assertThrows(RynBridgeError::class.java) {
            deserializer.deserialize(json)
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, exception.code)
    }
}
