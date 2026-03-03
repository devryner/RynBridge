import XCTest
@testable import RynBridge
@testable import RynBridgeStorage

final class StorageModuleTests: XCTestCase {
    func testSetAndGet() async throws {
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)

        _ = try await module.actions["set"]!(["key": "name", "value": "Alice"])
        let result = try await module.actions["get"]!(["key": "name"])
        XCTAssertEqual(result["value"]?.stringValue, "Alice")
    }

    func testGetNonExistentKey() async throws {
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)

        let result = try await module.actions["get"]!(["key": "missing"])
        XCTAssertTrue(result["value"]?.isNull == true)
    }

    func testRemove() async throws {
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)

        _ = try await module.actions["set"]!(["key": "temp", "value": "data"])
        _ = try await module.actions["remove"]!(["key": "temp"])
        let result = try await module.actions["get"]!(["key": "temp"])
        XCTAssertTrue(result["value"]?.isNull == true)
    }

    func testClear() async throws {
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)

        _ = try await module.actions["set"]!(["key": "a", "value": "1"])
        _ = try await module.actions["set"]!(["key": "b", "value": "2"])
        _ = try await module.actions["clear"]!([:])

        let keysResult = try await module.actions["keys"]!([:])
        let keys = keysResult["keys"]?.arrayValue ?? []
        XCTAssertTrue(keys.isEmpty)
    }

    func testKeys() async throws {
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)

        _ = try await module.actions["set"]!(["key": "x", "value": "1"])
        _ = try await module.actions["set"]!(["key": "y", "value": "2"])

        let result = try await module.actions["keys"]!([:])
        let keys = result["keys"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        XCTAssertEqual(keys.sorted(), ["x", "y"])
    }

    func testGetMissingKeyThrows() async {
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)

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
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)

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
        let provider = MockStorageProvider()
        let module = StorageModule(provider: provider)
        XCTAssertEqual(module.name, "storage")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockStorageProvider()
        bridge.register(StorageModule(provider: provider))

        // Set a value
        let setRequestJSON = """
        {"id":"req-set","module":"storage","action":"set","payload":{"key":"hello","value":"world"},"version":"0.1.0"}
        """
        transport.simulateIncoming(setRequestJSON)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Get the value
        transport.reset()
        let getRequestJSON = """
        {"id":"req-get","module":"storage","action":"get","payload":{"key":"hello"},"version":"0.1.0"}
        """
        transport.simulateIncoming(getRequestJSON)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.payload["value"]?.stringValue, "world")

        bridge.dispose()
    }
}

private final class MockStorageProvider: StorageProvider, @unchecked Sendable {
    private var store: [String: String] = [:]

    func get(key: String) -> String? {
        store[key]
    }

    func set(key: String, value: String) {
        store[key] = value
    }

    func remove(key: String) {
        store.removeValue(forKey: key)
    }

    func clear() {
        store.removeAll()
    }

    func keys() -> [String] {
        Array(store.keys).sorted()
    }
}
