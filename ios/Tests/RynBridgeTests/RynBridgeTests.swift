import XCTest
@testable import RynBridge

final class RynBridgeTests: XCTestCase {
    func testCallSendsRequestAndResolvesResponse() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))

        // Start the call in a task
        let task = Task<[String: AnyCodable], Error> {
            try await bridge.call("device", action: "getInfo")
        }

        // Wait for message to be sent
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Parse the sent request to get the ID
        let sentMessages = transport.sent
        XCTAssertEqual(sentMessages.count, 1)

        let decoder = JSONDecoder()
        let request = try decoder.decode(BridgeRequest.self, from: sentMessages[0].data(using: .utf8)!)
        XCTAssertEqual(request.module, "device")
        XCTAssertEqual(request.action, "getInfo")

        // Simulate native response
        let responseJSON = """
        {"id":"\(request.id)","status":"success","payload":{"platform":"ios"},"error":null}
        """
        transport.simulateIncoming(responseJSON)

        let result = try await task.value
        XCTAssertEqual(result["platform"]?.stringValue, "ios")

        bridge.dispose()
    }

    func testCallRejectsOnErrorResponse() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))

        let task = Task<[String: AnyCodable], Error> {
            try await bridge.call("device", action: "getInfo")
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        let request = try JSONDecoder().decode(BridgeRequest.self, from: transport.sent[0].data(using: .utf8)!)

        let responseJSON = """
        {"id":"\(request.id)","status":"error","payload":{},"error":{"code":"MODULE_NOT_FOUND","message":"Module not found"}}
        """
        transport.simulateIncoming(responseJSON)

        do {
            _ = try await task.value
            XCTFail("Expected error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .moduleNotFound)
        }

        bridge.dispose()
    }

    func testSendFireAndForget() {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport)

        bridge.send("device", action: "vibrate", payload: ["pattern": .array([.int(100)])])

        XCTAssertEqual(transport.sent.count, 1)
        bridge.dispose()
    }

    func testIncomingRequestRoutesToModule() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))

        let module = TestBridgeModule(name: "test", version: "0.1.0", actions: [
            "greet": { payload in
                let name = payload["name"]?.stringValue ?? "World"
                return ["greeting": .string("Hello, \(name)!")]
            }
        ])
        bridge.register(module)

        // Simulate incoming request from web
        let requestJSON = """
        {"id":"web-req-1","module":"test","action":"greet","payload":{"name":"Swift"},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        // Wait for async processing
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Bridge should have sent a response back
        XCTAssertEqual(transport.sent.count, 1)

        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "web-req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["greeting"]?.stringValue, "Hello, Swift!")

        bridge.dispose()
    }

    func testIncomingRequestModuleNotFound() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport)

        let requestJSON = """
        {"id":"web-req-2","module":"missing","action":"doSomething","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.status, .error)
        XCTAssertEqual(response.error?.code, "MODULE_NOT_FOUND")

        bridge.dispose()
    }

    func testDisposePreventsFurtherCalls() async {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport)

        bridge.dispose()

        do {
            _ = try await bridge.call("device", action: "getInfo")
            XCTFail("Expected error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .transportError)
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testDisposeSendIsNoop() {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport)

        bridge.dispose()
        bridge.send("device", action: "vibrate")

        XCTAssertEqual(transport.sent.count, 0)
    }

    func testEmitEventSendsRequestToTransport() {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport)

        bridge.emitEvent("push", action: "onNotification", payload: [
            "title": .string("Hello"),
            "body": .string("World")
        ])

        XCTAssertEqual(transport.sent.count, 1)

        let request = try! JSONDecoder().decode(BridgeRequest.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(request.module, "push")
        XCTAssertEqual(request.action, "onNotification")
        XCTAssertEqual(request.payload["title"]?.stringValue, "Hello")
        XCTAssertEqual(request.payload["body"]?.stringValue, "World")

        bridge.dispose()
    }

    func testEmitEventNoopAfterDispose() {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport)

        bridge.dispose()
        bridge.emitEvent("push", action: "onNotification")

        XCTAssertEqual(transport.sent.count, 0)
    }

    func testEmitEventWithEmptyPayload() {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport)

        bridge.emitEvent("navigation", action: "onDeepLink")

        XCTAssertEqual(transport.sent.count, 1)

        let request = try! JSONDecoder().decode(BridgeRequest.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(request.module, "navigation")
        XCTAssertEqual(request.action, "onDeepLink")
        XCTAssertTrue(request.payload.isEmpty)

        bridge.dispose()
    }
}

private struct TestBridgeModule: BridgeModule {
    let name: String
    let version: String
    let actions: [String: ActionHandler]
}
