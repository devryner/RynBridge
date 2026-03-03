import XCTest
@testable import RynBridge
@testable import RynBridgeSecureStorage

final class SecureStorageModuleTests: XCTestCase {
    func testSetAndGet() async throws {
        let provider = MockSecureStorageProvider()
        let module = SecureStorageModule(provider: provider)

        _ = try await module.actions["set"]!(["key": "token", "value": "abc123"])
        let result = try await module.actions["get"]!(["key": "token"])
        XCTAssertEqual(result["value"]?.stringValue, "abc123")
    }

    func testGetNonExistentKey() async throws {
        let provider = MockSecureStorageProvider()
        let module = SecureStorageModule(provider: provider)

        let result = try await module.actions["get"]!(["key": "missing"])
        XCTAssertTrue(result["value"]?.isNull == true)
    }

    func testRemove() async throws {
        let provider = MockSecureStorageProvider()
        let module = SecureStorageModule(provider: provider)

        _ = try await module.actions["set"]!(["key": "secret", "value": "data"])
        _ = try await module.actions["remove"]!(["key": "secret"])
        let result = try await module.actions["get"]!(["key": "secret"])
        XCTAssertTrue(result["value"]?.isNull == true)
    }

    func testHas() async throws {
        let provider = MockSecureStorageProvider()
        let module = SecureStorageModule(provider: provider)

        let before = try await module.actions["has"]!(["key": "token"])
        XCTAssertEqual(before["exists"]?.boolValue, false)

        _ = try await module.actions["set"]!(["key": "token", "value": "secret"])

        let after = try await module.actions["has"]!(["key": "token"])
        XCTAssertEqual(after["exists"]?.boolValue, true)
    }

    func testGetMissingKeyThrows() async {
        let provider = MockSecureStorageProvider()
        let module = SecureStorageModule(provider: provider)

        do {
            _ = try await module.actions["get"]!([:])
            XCTFail("Expected error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSetMissingValueThrows() async {
        let provider = MockSecureStorageProvider()
        let module = SecureStorageModule(provider: provider)

        do {
            _ = try await module.actions["set"]!(["key": "test"])
            XCTFail("Expected error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testModuleNameAndVersion() {
        let provider = MockSecureStorageProvider()
        let module = SecureStorageModule(provider: provider)
        XCTAssertEqual(module.name, "secure-storage")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockSecureStorageProvider()
        bridge.register(SecureStorageModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"secure-storage","action":"set","payload":{"key":"pw","value":"secret"},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)

        bridge.dispose()
    }
}

private final class MockSecureStorageProvider: SecureStorageProvider, @unchecked Sendable {
    private var store: [String: String] = [:]

    func get(key: String) throws -> String? {
        store[key]
    }

    func set(key: String, value: String) throws {
        store[key] = value
    }

    func remove(key: String) throws {
        store.removeValue(forKey: key)
    }

    func has(key: String) throws -> Bool {
        store[key] != nil
    }
}
