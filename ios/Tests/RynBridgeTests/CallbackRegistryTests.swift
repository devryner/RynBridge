import XCTest
@testable import RynBridge

final class CallbackRegistryTests: XCTestCase {
    func testResolveReturnsResponse() async throws {
        let registry = CallbackRegistry()
        let response = BridgeResponse(id: "req-1", status: .success, payload: ["value": "hello"])

        async let result = registry.register(id: "req-1", timeout: 5.0)

        // Small delay to ensure registration completes
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        let resolved = await registry.resolve(id: "req-1", response: response)
        XCTAssertTrue(resolved)

        let actual = try await result
        XCTAssertEqual(actual.id, "req-1")
        XCTAssertEqual(actual.status, .success)
        XCTAssertEqual(actual.payload["value"]?.stringValue, "hello")
    }

    func testResolveNonExistentIDReturnsFalse() async {
        let registry = CallbackRegistry()
        let response = BridgeResponse(id: "nonexistent", status: .success)
        let resolved = await registry.resolve(id: "nonexistent", response: response)
        XCTAssertFalse(resolved)
    }

    func testTimeout() async {
        let registry = CallbackRegistry()

        do {
            _ = try await registry.register(id: "timeout-req", timeout: 0.1)
            XCTFail("Expected timeout error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .timeout)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testClearCancelsAllPending() async throws {
        let registry = CallbackRegistry()

        let expectation = XCTestExpectation(description: "callback rejected")

        Task {
            do {
                _ = try await registry.register(id: "clear-req", timeout: 10.0)
                XCTFail("Expected error after clear")
            } catch let error as RynBridgeError {
                XCTAssertEqual(error.code, .transportError)
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error type")
            }
        }

        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        await registry.clear()

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testPendingCount() async throws {
        let registry = CallbackRegistry()

        Task { _ = try? await registry.register(id: "a", timeout: 10.0) }
        Task { _ = try? await registry.register(id: "b", timeout: 10.0) }

        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        let count = await registry.pendingCount
        XCTAssertEqual(count, 2)

        await registry.clear()
    }
}
