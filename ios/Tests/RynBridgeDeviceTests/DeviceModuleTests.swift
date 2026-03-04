import XCTest
@testable import RynBridge
@testable import RynBridgeDevice

final class DeviceModuleTests: XCTestCase {
    func testGetInfo() async throws {
        let provider = MockDeviceInfoProvider()
        let module = DeviceModule(provider: provider)
        let handler = module.actions["getInfo"]!

        let result = try await handler([:])
        XCTAssertEqual(result["platform"]?.stringValue, "ios")
        XCTAssertEqual(result["osVersion"]?.stringValue, "17.0")
        XCTAssertEqual(result["model"]?.stringValue, "iPhone")
        XCTAssertEqual(result["appVersion"]?.stringValue, "1.0.0")
    }

    func testGetBattery() async throws {
        let provider = MockDeviceInfoProvider()
        let module = DeviceModule(provider: provider)
        let handler = module.actions["getBattery"]!

        let result = try await handler([:])
        XCTAssertEqual(result["level"]?.intValue, 85)
        XCTAssertEqual(result["isCharging"]?.boolValue, true)
    }

    func testGetScreen() async throws {
        let provider = MockDeviceInfoProvider()
        let module = DeviceModule(provider: provider)
        let handler = module.actions["getScreen"]!

        let result = try await handler([:])
        XCTAssertEqual(result["width"]?.doubleValue, 390.0)
        XCTAssertEqual(result["height"]?.doubleValue, 844.0)
        XCTAssertEqual(result["scale"]?.doubleValue, 3.0)
        XCTAssertEqual(result["orientation"]?.stringValue, "portrait")
    }

    func testVibrate() async throws {
        let provider = MockDeviceInfoProvider()
        let module = DeviceModule(provider: provider)
        let handler = module.actions["vibrate"]!

        let result = try await handler(["pattern": .array([.int(100), .int(200)])])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastVibratePattern, [100, 200])
    }

    func testVibrateWithoutPattern() async throws {
        let provider = MockDeviceInfoProvider()
        let module = DeviceModule(provider: provider)
        let handler = module.actions["vibrate"]!

        _ = try await handler([:])
        XCTAssertEqual(provider.lastVibratePattern, [])
    }

    func testModuleNameAndVersion() {
        let provider = MockDeviceInfoProvider()
        let module = DeviceModule(provider: provider)
        XCTAssertEqual(module.name, "device")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockDeviceInfoProvider()
        bridge.register(DeviceModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"device","action":"getInfo","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["platform"]?.stringValue, "ios")

        bridge.dispose()
    }
}

private final class MockDeviceInfoProvider: DeviceInfoProvider, @unchecked Sendable {
    var lastVibratePattern: [Int]?

    func getDeviceInfo() -> DeviceInfo {
        DeviceInfo(platform: "ios", osVersion: "17.0", model: "iPhone", appVersion: "1.0.0")
    }

    func getBatteryInfo() -> BatteryInfo {
        BatteryInfo(level: 85, isCharging: true)
    }

    func getScreenInfo() -> ScreenInfo {
        ScreenInfo(width: 390.0, height: 844.0, scale: 3.0, orientation: "portrait")
    }

    func vibrate(pattern: [Int]) {
        lastVibratePattern = pattern
    }

    func capturePhoto(quality: Double, camera: String) async throws -> CapturePhotoResult {
        CapturePhotoResult(imageBase64: "", width: 100, height: 100)
    }

    func getLocation() async throws -> LocationInfo {
        LocationInfo(latitude: 37.5, longitude: 127.0, accuracy: 5.0)
    }

    func authenticate(reason: String) async throws -> AuthenticateResult {
        AuthenticateResult(success: true)
    }
}
