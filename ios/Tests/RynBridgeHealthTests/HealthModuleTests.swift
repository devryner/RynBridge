import XCTest
@testable import RynBridge
@testable import RynBridgeHealth

final class HealthModuleTests: XCTestCase {
    func testRequestPermission() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([
            "readTypes": .array([.string("steps"), .string("heartRate")]),
            "writeTypes": .array([.string("steps")]),
        ])
        XCTAssertEqual(result["granted"]?.boolValue, true)
        XCTAssertEqual(provider.lastReadTypes, ["steps", "heartRate"])
        XCTAssertEqual(provider.lastWriteTypes, ["steps"])
    }

    func testRequestPermissionWithoutWriteTypes() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([
            "readTypes": .array([.string("steps")]),
        ])
        XCTAssertEqual(result["granted"]?.boolValue, true)
        XCTAssertEqual(provider.lastWriteTypes, [])
    }

    func testRequestPermissionMissingReadTypes() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error for missing readTypes")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testGetPermissionStatus() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["getPermissionStatus"]!

        let result = try await handler([:])
        XCTAssertEqual(result["status"]?.stringValue, "authorized")
    }

    func testQueryData() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["queryData"]!

        let result = try await handler([
            "dataType": .string("heartRate"),
            "startDate": .string("2026-01-01"),
            "endDate": .string("2026-01-31"),
            "limit": .int(10),
        ])
        let records = result["records"]?.arrayValue
        XCTAssertNotNil(records)
        XCTAssertEqual(records?.count, 1)
        XCTAssertEqual(records?.first?.dictionaryValue?["value"]?.doubleValue, 72.0)
        XCTAssertEqual(provider.lastQueryLimit, 10)
    }

    func testQueryDataWithoutLimit() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["queryData"]!

        _ = try await handler([
            "dataType": .string("heartRate"),
            "startDate": .string("2026-01-01"),
            "endDate": .string("2026-01-31"),
        ])
        XCTAssertNil(provider.lastQueryLimit)
    }

    func testQueryDataMissingFields() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["queryData"]!

        do {
            _ = try await handler(["dataType": .string("heartRate")])
            XCTFail("Expected error for missing startDate")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testWriteData() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["writeData"]!

        let result = try await handler([
            "dataType": .string("bodyMass"),
            "value": .double(75.5),
            "unit": .string("kg"),
            "startDate": .string("2026-03-01T08:00:00Z"),
            "endDate": .string("2026-03-01T08:00:00Z"),
        ])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastWriteDataType, "bodyMass")
        XCTAssertEqual(provider.lastWriteValue, 75.5)
        XCTAssertEqual(provider.lastWriteUnit, "kg")
    }

    func testWriteDataMissingFields() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["writeData"]!

        do {
            _ = try await handler(["dataType": .string("bodyMass")])
            XCTFail("Expected error for missing value")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testGetSteps() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["getSteps"]!

        let result = try await handler([
            "startDate": .string("2026-03-01"),
            "endDate": .string("2026-03-01"),
        ])
        XCTAssertEqual(result["steps"]?.doubleValue, 8500.0)
    }

    func testGetStepsMissingFields() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["getSteps"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error for missing startDate")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testIsAvailable() async throws {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        let handler = module.actions["isAvailable"]!

        let result = try await handler([:])
        XCTAssertEqual(result["available"]?.boolValue, true)
    }

    func testModuleNameAndVersion() {
        let provider = MockHealthProvider()
        let module = HealthModule(provider: provider)
        XCTAssertEqual(module.name, "health")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockHealthProvider()
        bridge.register(HealthModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"health","action":"isAvailable","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["available"]?.boolValue, true)

        bridge.dispose()
    }
}

private final class MockHealthProvider: HealthProvider, @unchecked Sendable {
    var lastReadTypes: [String]?
    var lastWriteTypes: [String]?
    var lastQueryLimit: Int?
    var lastWriteDataType: String?
    var lastWriteValue: Double?
    var lastWriteUnit: String?

    func requestPermission(readTypes: [String], writeTypes: [String]) async throws -> Bool {
        lastReadTypes = readTypes
        lastWriteTypes = writeTypes
        return true
    }

    func getPermissionStatus() async throws -> String {
        "authorized"
    }

    func queryData(dataType: String, startDate: String, endDate: String, limit: Int?) async throws -> [[String: AnyCodable]] {
        lastQueryLimit = limit
        return [["value": .double(72.0), "date": .string("2026-01-15"), "unit": .string("bpm")]]
    }

    func writeData(dataType: String, value: Double, unit: String, startDate: String, endDate: String) async throws -> Bool {
        lastWriteDataType = dataType
        lastWriteValue = value
        lastWriteUnit = unit
        return true
    }

    func getSteps(startDate: String, endDate: String) async throws -> Double {
        8500.0
    }

    func isAvailable() async throws -> Bool {
        true
    }
}
