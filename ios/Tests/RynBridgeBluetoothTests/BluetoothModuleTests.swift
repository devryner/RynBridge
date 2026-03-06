import XCTest
@testable import RynBridge
@testable import RynBridgeBluetooth

final class BluetoothModuleTests: XCTestCase {
    func testStartScanWithServiceUUIDs() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["startScan"]!

        let result = try await handler([
            "serviceUUIDs": .array([.string("180D"), .string("180F")])
        ])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastScanServiceUUIDs, ["180D", "180F"])
    }

    func testStartScanWithoutServiceUUIDs() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["startScan"]!

        let result = try await handler([:])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertNil(provider.lastScanServiceUUIDs)
    }

    func testStopScan() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["stopScan"]!

        let result = try await handler([:])
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(provider.stopScanCalled)
    }

    func testConnect() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["connect"]!

        let result = try await handler(["deviceId": .string("device-abc")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastConnectedDeviceId, "device-abc")
    }

    func testConnectMissingDeviceId() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["connect"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error for missing deviceId")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testDisconnect() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["disconnect"]!

        let result = try await handler(["deviceId": .string("device-abc")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastDisconnectedDeviceId, "device-abc")
    }

    func testGetServices() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["getServices"]!

        let result = try await handler(["deviceId": .string("device-abc")])
        let services = result["services"]?.arrayValue
        XCTAssertNotNil(services)
        XCTAssertEqual(services?.count, 1)
        XCTAssertEqual(services?.first?.dictionaryValue?["uuid"]?.stringValue, "180D")
    }

    func testReadCharacteristic() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["readCharacteristic"]!

        let result = try await handler([
            "deviceId": .string("device-abc"),
            "serviceUUID": .string("180D"),
            "characteristicUUID": .string("2A37"),
        ])
        XCTAssertEqual(result["value"]?.stringValue, "mock-char-value")
    }

    func testReadCharacteristicMissingFields() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["readCharacteristic"]!

        do {
            _ = try await handler(["deviceId": .string("device-abc")])
            XCTFail("Expected error for missing serviceUUID")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testWriteCharacteristic() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["writeCharacteristic"]!

        let result = try await handler([
            "deviceId": .string("device-abc"),
            "serviceUUID": .string("180D"),
            "characteristicUUID": .string("2A37"),
            "value": .string("AQID"),
        ])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastWrittenValue, "AQID")
    }

    func testRequestPermission() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([:])
        XCTAssertEqual(result["granted"]?.boolValue, true)
    }

    func testGetState() async throws {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        let handler = module.actions["getState"]!

        let result = try await handler([:])
        XCTAssertEqual(result["state"]?.stringValue, "poweredOn")
    }

    func testModuleNameAndVersion() {
        let provider = MockBluetoothProvider()
        let module = BluetoothModule(provider: provider)
        XCTAssertEqual(module.name, "bluetooth")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockBluetoothProvider()
        bridge.register(BluetoothModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"bluetooth","action":"getState","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["state"]?.stringValue, "poweredOn")

        bridge.dispose()
    }
}

private final class MockBluetoothProvider: BluetoothProvider, @unchecked Sendable {
    var lastScanServiceUUIDs: [String]?
    var stopScanCalled = false
    var lastConnectedDeviceId: String?
    var lastDisconnectedDeviceId: String?
    var lastWrittenValue: String?

    func startScan(serviceUUIDs: [String]?) async throws -> Bool {
        lastScanServiceUUIDs = serviceUUIDs
        return true
    }

    func stopScan() {
        stopScanCalled = true
    }

    func connect(deviceId: String) async throws -> Bool {
        lastConnectedDeviceId = deviceId
        return true
    }

    func disconnect(deviceId: String) async throws -> Bool {
        lastDisconnectedDeviceId = deviceId
        return true
    }

    func getServices(deviceId: String) async throws -> [[String: AnyCodable]] {
        [["uuid": .string("180D"), "name": .string("Heart Rate")]]
    }

    func readCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String) async throws -> String {
        "mock-char-value"
    }

    func writeCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String, value: String) async throws -> Bool {
        lastWrittenValue = value
        return true
    }

    func requestPermission() async throws -> Bool {
        true
    }

    func getState() async throws -> String {
        "poweredOn"
    }
}
