package com.devryner.rynbridge.core

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class MessageSerializerTest {

    @Test
    fun `createRequest generates UUID`() {
        val serializer = MessageSerializer(version = "0.1.0")
        val request = serializer.createRequest(module = "device", action = "getInfo")
        assertTrue(request.id.isNotEmpty())
        assertEquals("device", request.module)
        assertEquals("getInfo", request.action)
        assertEquals("0.1.0", request.version)
        assertTrue(request.payload.isEmpty())
    }

    @Test
    fun `createRequest with payload`() {
        val serializer = MessageSerializer()
        val request = serializer.createRequest(
            module = "storage",
            action = "set",
            payload = mapOf("key" to BridgeValue.string("test"), "value" to BridgeValue.string("hello"))
        )
        assertEquals("test", request.payload["key"]?.stringValue)
        assertEquals("hello", request.payload["value"]?.stringValue)
    }

    @Test
    fun `serialize request`() {
        val serializer = MessageSerializer(version = "0.1.0")
        val request = BridgeRequest(id = "test-id", module = "device", action = "getInfo", version = "0.1.0")
        val json = serializer.serialize(request)
        assertTrue(json.contains("\"id\":\"test-id\""))
        assertTrue(json.contains("\"module\":\"device\""))
        assertTrue(json.contains("\"action\":\"getInfo\""))
    }

    @Test
    fun `serialize response`() {
        val serializer = MessageSerializer()
        val response = BridgeResponse(
            id = "test-id",
            status = ResponseStatus.success,
            payload = mapOf("value" to BridgeValue.string("hello"))
        )
        val json = serializer.serialize(response)
        assertTrue(json.contains("\"id\":\"test-id\""))
        assertTrue(json.contains("\"status\":\"success\""))
    }

    @Test
    fun `each request gets unique ID`() {
        val serializer = MessageSerializer()
        val r1 = serializer.createRequest(module = "m", action = "a")
        val r2 = serializer.createRequest(module = "m", action = "a")
        assertNotEquals(r1.id, r2.id)
    }

    @Test
    fun `createResponse with error`() {
        val serializer = MessageSerializer()
        val errorData = BridgeErrorData(code = "TIMEOUT", message = "Request timed out")
        val response = serializer.createResponse(id = "r1", status = ResponseStatus.error, error = errorData)
        assertEquals(ResponseStatus.error, response.status)
        assertEquals("TIMEOUT", response.error?.code)
        val json = serializer.serialize(response)
        assertTrue(json.contains("TIMEOUT"))
    }
}
