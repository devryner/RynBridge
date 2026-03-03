package io.rynbridge.core

import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class BridgeValueTest {

    private val json = Json { encodeDefaults = true }

    @Test
    fun `serialize and deserialize string`() {
        val value = BridgeValue.string("hello")
        val encoded = json.encodeToString(BridgeValueSerializer, value)
        val decoded = json.decodeFromString(BridgeValueSerializer, encoded)
        assertEquals(BridgeValue.StringValue("hello"), decoded)
        assertEquals("hello", decoded.stringValue)
    }

    @Test
    fun `serialize and deserialize int`() {
        val value = BridgeValue.int(42)
        val encoded = json.encodeToString(BridgeValueSerializer, value)
        val decoded = json.decodeFromString(BridgeValueSerializer, encoded)
        assertEquals(BridgeValue.IntValue(42), decoded)
        assertEquals(42L, decoded.intValue)
    }

    @Test
    fun `serialize and deserialize bool`() {
        val value = BridgeValue.bool(true)
        val encoded = json.encodeToString(BridgeValueSerializer, value)
        val decoded = json.decodeFromString(BridgeValueSerializer, encoded)
        assertEquals(BridgeValue.BoolValue(true), decoded)
        assertEquals(true, decoded.boolValue)
    }

    @Test
    fun `serialize and deserialize double`() {
        val value = BridgeValue.double(3.14)
        val encoded = json.encodeToString(BridgeValueSerializer, value)
        val decoded = json.decodeFromString(BridgeValueSerializer, encoded)
        assertEquals(3.14, decoded.doubleValue!!, 0.001)
    }

    @Test
    fun `serialize and deserialize null`() {
        val value = BridgeValue.nullValue()
        val encoded = json.encodeToString(BridgeValueSerializer, value)
        val decoded = json.decodeFromString(BridgeValueSerializer, encoded)
        assertTrue(decoded.isNull)
    }

    @Test
    fun `serialize and deserialize array`() {
        val value = BridgeValue.array(listOf(BridgeValue.int(1), BridgeValue.int(2), BridgeValue.int(3)))
        val encoded = json.encodeToString(BridgeValueSerializer, value)
        val decoded = json.decodeFromString(BridgeValueSerializer, encoded)
        assertEquals(3, decoded.arrayValue?.size)
    }

    @Test
    fun `serialize and deserialize dictionary`() {
        val value = BridgeValue.dict(mapOf("key" to BridgeValue.string("value")))
        val encoded = json.encodeToString(BridgeValueSerializer, value)
        val decoded = json.decodeFromString(BridgeValueSerializer, encoded)
        assertEquals("value", decoded.dictionaryValue?.get("key")?.stringValue)
    }

    @Test
    fun `nested structure`() {
        val jsonStr = """{"name":"test","count":5,"active":true,"items":[1,2],"meta":{"key":"val"}}"""
        val decoded = json.decodeFromString(BridgeValueMapSerializer, jsonStr)
        assertEquals("test", decoded["name"]?.stringValue)
        assertEquals(5L, decoded["count"]?.intValue)
        assertEquals(true, decoded["active"]?.boolValue)
        assertEquals(2, decoded["items"]?.arrayValue?.size)
        assertEquals("val", decoded["meta"]?.dictionaryValue?.get("key")?.stringValue)
    }

    @Test
    fun `int coerces to double`() {
        val value = BridgeValue.int(42)
        assertEquals(42.0, value.doubleValue)
    }

    @Test
    fun `wrong type accessors return null`() {
        val value = BridgeValue.string("hello")
        assertNull(value.intValue)
        assertNull(value.boolValue)
        assertNull(value.arrayValue)
        assertNull(value.dictionaryValue)
        assertFalse(value.isNull)
    }
}
