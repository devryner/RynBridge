package io.rynbridge.device

import io.rynbridge.core.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class DeviceModuleTest {

    @Test
    fun `getInfo returns device info`() = runTest {
        val provider = MockDeviceInfoProvider()
        val module = DeviceModule(provider)
        val handler = module.actions["getInfo"]!!

        val result = handler(emptyMap())
        assertEquals("android", result["platform"]?.stringValue)
        assertEquals("14", result["osVersion"]?.stringValue)
        assertEquals("Pixel 8", result["model"]?.stringValue)
        assertEquals("1.0.0", result["appVersion"]?.stringValue)
    }

    @Test
    fun `getBattery returns battery info`() = runTest {
        val provider = MockDeviceInfoProvider()
        val module = DeviceModule(provider)
        val handler = module.actions["getBattery"]!!

        val result = handler(emptyMap())
        assertEquals(85L, result["level"]?.intValue)
        assertEquals(true, result["isCharging"]?.boolValue)
    }

    @Test
    fun `getScreen returns screen info`() = runTest {
        val provider = MockDeviceInfoProvider()
        val module = DeviceModule(provider)
        val handler = module.actions["getScreen"]!!

        val result = handler(emptyMap())
        assertEquals(390.0, result["width"]?.doubleValue)
        assertEquals(844.0, result["height"]?.doubleValue)
        assertEquals(3.0, result["scale"]?.doubleValue)
        assertEquals("portrait", result["orientation"]?.stringValue)
    }

    @Test
    fun `vibrate with pattern`() = runTest {
        val provider = MockDeviceInfoProvider()
        val module = DeviceModule(provider)
        val handler = module.actions["vibrate"]!!

        val result = handler(mapOf("pattern" to BridgeValue.array(listOf(BridgeValue.int(100), BridgeValue.int(200)))))
        assertTrue(result.isEmpty())
        assertEquals(listOf(100, 200), provider.lastVibratePattern)
    }

    @Test
    fun `vibrate without pattern`() = runTest {
        val provider = MockDeviceInfoProvider()
        val module = DeviceModule(provider)
        val handler = module.actions["vibrate"]!!

        handler(emptyMap())
        assertEquals(emptyList<Int>(), provider.lastVibratePattern)
    }

    @Test
    fun `module name and version`() {
        val provider = MockDeviceInfoProvider()
        val module = DeviceModule(provider)
        assertEquals("device", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockDeviceInfoProvider()
        bridge.register(DeviceModule(provider))

        val requestJSON = """{"id":"req-1","module":"device","action":"getInfo","payload":{},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        withContext(Dispatchers.Default) { delay(200) }

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertEquals("android", response.payload["platform"]?.stringValue)

        bridge.dispose()
    }
}

private class MockDeviceInfoProvider : DeviceInfoProvider {
    var lastVibratePattern: List<Int>? = null

    override fun getDeviceInfo() = DeviceInfo(
        platform = "android",
        osVersion = "14",
        model = "Pixel 8",
        appVersion = "1.0.0"
    )

    override fun getBatteryInfo() = BatteryInfo(level = 85, isCharging = true)

    override fun getScreenInfo() = ScreenInfo(
        width = 390.0,
        height = 844.0,
        scale = 3.0,
        orientation = "portrait"
    )

    override fun vibrate(pattern: List<Int>) {
        lastVibratePattern = pattern
    }

    override suspend fun capturePhoto(quality: Double, camera: String): CapturePhotoResult {
        return CapturePhotoResult(imageBase64 = "mockBase64", width = 1920, height = 1080)
    }

    override suspend fun getLocation(): LocationInfo {
        return LocationInfo(latitude = 37.5665, longitude = 126.978, accuracy = 10.0)
    }

    override suspend fun authenticate(reason: String): AuthenticateResult {
        return AuthenticateResult(success = true)
    }
}
