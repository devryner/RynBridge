import XCTest
@testable import RynBridge
@testable import RynBridgePush

final class PushModuleTests: XCTestCase {
    func testRegister() async throws {
        let provider = MockPushProvider()
        let module = PushModule(provider: provider)
        let handler = module.actions["register"]!

        let result = try await handler([:])
        XCTAssertEqual(result["token"]?.stringValue, "apns-token-abc123")
        XCTAssertEqual(result["platform"]?.stringValue, "ios")
    }

    func testUnregister() async throws {
        let provider = MockPushProvider()
        let module = PushModule(provider: provider)
        let handler = module.actions["unregister"]!

        let result = try await handler([:])
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(provider.unregisterCalled)
    }

    func testGetToken() async throws {
        let provider = MockPushProvider()
        let module = PushModule(provider: provider)
        let handler = module.actions["getToken"]!

        let result = try await handler([:])
        XCTAssertEqual(result["token"]?.stringValue, "apns-token-abc123")
    }

    func testRequestPermission() async throws {
        let provider = MockPushProvider()
        let module = PushModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([:])
        XCTAssertEqual(result["granted"]?.boolValue, true)
    }

    func testGetPermissionStatus() async throws {
        let provider = MockPushProvider()
        let module = PushModule(provider: provider)
        let handler = module.actions["getPermissionStatus"]!

        let result = try await handler([:])
        XCTAssertEqual(result["status"]?.stringValue, "granted")
    }

    func testGetInitialNotification() async throws {
        let provider = MockPushProvider()
        let module = PushModule(provider: provider)
        let handler = module.actions["getInitialNotification"]!

        let result = try await handler([:])
        XCTAssertEqual(result["title"]?.stringValue, "Welcome")
        XCTAssertEqual(result["body"]?.stringValue, "You have a new message")
    }

    func testGetInitialNotificationWhenNil() async throws {
        let provider = MockPushProvider()
        provider.initialNotification = nil
        let module = PushModule(provider: provider)
        let handler = module.actions["getInitialNotification"]!

        let result = try await handler([:])
        XCTAssertTrue(result["title"]?.isNull ?? false)
        XCTAssertTrue(result["body"]?.isNull ?? false)
        XCTAssertTrue(result["data"]?.isNull ?? false)
    }

    func testModuleNameAndVersion() {
        let provider = MockPushProvider()
        let module = PushModule(provider: provider)
        XCTAssertEqual(module.name, "push")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockPushProvider()
        bridge.register(PushModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"push","action":"register","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["token"]?.stringValue, "apns-token-abc123")

        bridge.dispose()
    }
}

private final class MockPushProvider: PushProvider, @unchecked Sendable {
    var unregisterCalled = false
    var initialNotification: PushNotificationData? = PushNotificationData(
        title: "Welcome",
        body: "You have a new message",
        data: ["key": .string("value")]
    )

    func register() async throws -> PushRegistration {
        PushRegistration(token: "apns-token-abc123", platform: "ios")
    }

    func unregister() async throws {
        unregisterCalled = true
    }

    func getToken() async throws -> String? {
        "apns-token-abc123"
    }

    func requestPermission() async throws -> Bool {
        true
    }

    func getPermissionStatus() async throws -> PushPermissionStatus {
        PushPermissionStatus(status: "granted")
    }

    func getInitialNotification() async throws -> PushNotificationData? {
        initialNotification
    }
}
