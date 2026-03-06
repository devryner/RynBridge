package io.rynbridge.health

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class HealthModuleTest {

    @Test
    fun `requestPermission returns granted`() = runTest {
        val provider = MockHealthProvider()
        val module = HealthModule(provider)
        val handler = module.actions["requestPermission"]!!

        val result = handler(mapOf(
            "readTypes" to BridgeValue.array(listOf(BridgeValue.string("steps"), BridgeValue.string("heartRate"))),
            "writeTypes" to BridgeValue.array(listOf(BridgeValue.string("steps")))
        ))
        assertEquals(true, result["granted"]?.boolValue)
        assertEquals(listOf("steps", "heartRate"), provider.lastReadTypes)
        assertEquals(listOf("steps"), provider.lastWriteTypes)
    }

    @Test
    fun `getPermissionStatus returns status`() = runTest {
        val provider = MockHealthProvider()
        val module = HealthModule(provider)
        val handler = module.actions["getPermissionStatus"]!!

        val result = handler(emptyMap())
        assertEquals("granted", result["status"]?.stringValue)
    }

    @Test
    fun `queryData returns records`() = runTest {
        val provider = MockHealthProvider()
        val module = HealthModule(provider)
        val handler = module.actions["queryData"]!!

        val result = handler(mapOf(
            "dataType" to BridgeValue.string("steps"),
            "startDate" to BridgeValue.string("2026-03-01"),
            "endDate" to BridgeValue.string("2026-03-06"),
            "limit" to BridgeValue.int(10)
        ))
        val records = result["records"]?.arrayValue
        assertNotNull(records)
        assertEquals(1, records!!.size)
        assertEquals("steps", records[0].dictionaryValue?.get("type")?.stringValue)
    }

    @Test
    fun `writeData returns success`() = runTest {
        val provider = MockHealthProvider()
        val module = HealthModule(provider)
        val handler = module.actions["writeData"]!!

        val result = handler(mapOf(
            "dataType" to BridgeValue.string("steps"),
            "value" to BridgeValue.double(1000.0),
            "unit" to BridgeValue.string("count"),
            "startDate" to BridgeValue.string("2026-03-06T08:00:00"),
            "endDate" to BridgeValue.string("2026-03-06T09:00:00")
        ))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("steps", provider.lastWriteDataType)
        assertEquals(1000.0, provider.lastWriteValue)
    }

    @Test
    fun `getSteps returns step count`() = runTest {
        val provider = MockHealthProvider()
        val module = HealthModule(provider)
        val handler = module.actions["getSteps"]!!

        val result = handler(mapOf(
            "startDate" to BridgeValue.string("2026-03-06"),
            "endDate" to BridgeValue.string("2026-03-06")
        ))
        assertEquals(8500.0, result["steps"]?.doubleValue)
    }

    @Test
    fun `isAvailable returns true`() = runTest {
        val provider = MockHealthProvider()
        val module = HealthModule(provider)
        val handler = module.actions["isAvailable"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["available"]?.boolValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockHealthProvider()
        val module = HealthModule(provider)
        assertEquals("health", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockHealthProvider : HealthProvider {
    var lastReadTypes: List<String>? = null
    var lastWriteTypes: List<String>? = null
    var lastWriteDataType: String? = null
    var lastWriteValue: Double? = null

    override suspend fun requestPermission(readTypes: List<String>, writeTypes: List<String>): Boolean {
        lastReadTypes = readTypes
        lastWriteTypes = writeTypes
        return true
    }

    override suspend fun getPermissionStatus(): String = "granted"

    override suspend fun queryData(dataType: String, startDate: String, endDate: String, limit: Int?): List<Map<String, BridgeValue>> =
        listOf(mapOf(
            "type" to BridgeValue.string("steps"),
            "value" to BridgeValue.double(5000.0),
            "date" to BridgeValue.string("2026-03-05")
        ))

    override suspend fun writeData(dataType: String, value: Double, unit: String, startDate: String, endDate: String): Boolean {
        lastWriteDataType = dataType
        lastWriteValue = value
        return true
    }

    override suspend fun getSteps(startDate: String, endDate: String): Double = 8500.0

    override suspend fun isAvailable(): Boolean = true
}
