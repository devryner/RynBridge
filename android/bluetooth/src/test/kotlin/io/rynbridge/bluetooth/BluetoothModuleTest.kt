package io.rynbridge.bluetooth

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class BluetoothModuleTest {

    @Test
    fun `startScan returns success`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["startScan"]!!

        val result = handler(mapOf(
            "serviceUUIDs" to BridgeValue.array(listOf(BridgeValue.string("180D")))
        ))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals(listOf("180D"), provider.lastScanUUIDs)
    }

    @Test
    fun `startScan without serviceUUIDs`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["startScan"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["success"]?.boolValue)
        assertNull(provider.lastScanUUIDs)
    }

    @Test
    fun `stopScan calls provider`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["stopScan"]!!

        val result = handler(emptyMap())
        assertTrue(result.isEmpty())
        assertTrue(provider.stopScanCalled)
    }

    @Test
    fun `connect returns success`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["connect"]!!

        val result = handler(mapOf("deviceId" to BridgeValue.string("dev-1")))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("dev-1", provider.lastConnectDeviceId)
    }

    @Test
    fun `disconnect returns success`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["disconnect"]!!

        val result = handler(mapOf("deviceId" to BridgeValue.string("dev-1")))
        assertEquals(true, result["success"]?.boolValue)
    }

    @Test
    fun `getServices returns service list`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["getServices"]!!

        val result = handler(mapOf("deviceId" to BridgeValue.string("dev-1")))
        val services = result["services"]?.arrayValue
        assertNotNull(services)
        assertEquals(1, services!!.size)
        assertEquals("180D", services[0].dictionaryValue?.get("uuid")?.stringValue)
    }

    @Test
    fun `readCharacteristic returns value`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["readCharacteristic"]!!

        val result = handler(mapOf(
            "deviceId" to BridgeValue.string("dev-1"),
            "serviceUUID" to BridgeValue.string("180D"),
            "characteristicUUID" to BridgeValue.string("2A37")
        ))
        assertEquals("AQID", result["value"]?.stringValue)
    }

    @Test
    fun `writeCharacteristic returns success`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["writeCharacteristic"]!!

        val result = handler(mapOf(
            "deviceId" to BridgeValue.string("dev-1"),
            "serviceUUID" to BridgeValue.string("180D"),
            "characteristicUUID" to BridgeValue.string("2A37"),
            "value" to BridgeValue.string("BAAD")
        ))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("BAAD", provider.lastWriteValue)
    }

    @Test
    fun `requestPermission returns granted`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["requestPermission"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["granted"]?.boolValue)
    }

    @Test
    fun `getState returns state`() = runTest {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        val handler = module.actions["getState"]!!

        val result = handler(emptyMap())
        assertEquals("poweredOn", result["state"]?.stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockBluetoothProvider()
        val module = BluetoothModule(provider)
        assertEquals("bluetooth", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockBluetoothProvider : BluetoothProvider {
    var lastScanUUIDs: List<String>? = null
    var stopScanCalled = false
    var lastConnectDeviceId: String? = null
    var lastWriteValue: String? = null

    override suspend fun startScan(serviceUUIDs: List<String>?): Boolean {
        lastScanUUIDs = serviceUUIDs
        return true
    }

    override fun stopScan() {
        stopScanCalled = true
    }

    override suspend fun connect(deviceId: String): Boolean {
        lastConnectDeviceId = deviceId
        return true
    }

    override suspend fun disconnect(deviceId: String): Boolean = true

    override suspend fun getServices(deviceId: String): List<Map<String, BridgeValue>> =
        listOf(mapOf("uuid" to BridgeValue.string("180D"), "name" to BridgeValue.string("Heart Rate")))

    override suspend fun readCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String): String =
        "AQID"

    override suspend fun writeCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String, value: String): Boolean {
        lastWriteValue = value
        return true
    }

    override suspend fun requestPermission(): Boolean = true

    override suspend fun getState(): String = "poweredOn"
}
