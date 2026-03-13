import XCTest
@testable import RynBridge
@testable import RynBridgePushAPNs

final class PushAPNsModuleTests: XCTestCase {
    func testGetToken() async throws {
        let provider = MockAPNsPushProvider()
        let module = PushAPNsModule(provider: provider)
        let handler = module.actions["getToken"]!

        let result = try await handler([:])
        XCTAssertEqual(result["token"]?.stringValue, "apns-device-token-abc123")
    }

    func testGetTokenWhenNil() async throws {
        let provider = MockAPNsPushProvider(token: nil)
        let module = PushAPNsModule(provider: provider)
        let handler = module.actions["getToken"]!

        let result = try await handler([:])
        XCTAssertTrue(result["token"]?.isNull ?? false)
    }

    func testSetBadgeCount() async throws {
        let provider = MockAPNsPushProvider()
        let module = PushAPNsModule(provider: provider)
        let handler = module.actions["setBadgeCount"]!

        let result = try await handler(["count": .int(5)])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.badgeCount, 5)
    }

    func testSetBadgeCountMissingField() async throws {
        let provider = MockAPNsPushProvider()
        let module = PushAPNsModule(provider: provider)
        let handler = module.actions["setBadgeCount"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testGetBadgeCount() async throws {
        let provider = MockAPNsPushProvider()
        provider.badgeCount = 3
        let module = PushAPNsModule(provider: provider)
        let handler = module.actions["getBadgeCount"]!

        let result = try await handler([:])
        XCTAssertEqual(result["count"]?.intValue, 3)
    }

    func testRemoveAllDeliveredNotifications() async throws {
        let provider = MockAPNsPushProvider()
        let module = PushAPNsModule(provider: provider)
        let handler = module.actions["removeAllDeliveredNotifications"]!

        let result = try await handler([:])
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(provider.removeAllDeliveredCalled)
    }

    func testGetDeliveredNotificationCount() async throws {
        let provider = MockAPNsPushProvider()
        provider.deliveredCount = 7
        let module = PushAPNsModule(provider: provider)
        let handler = module.actions["getDeliveredNotificationCount"]!

        let result = try await handler([:])
        XCTAssertEqual(result["count"]?.intValue, 7)
    }

    func testModuleNameAndVersion() {
        let provider = MockAPNsPushProvider()
        let module = PushAPNsModule(provider: provider)
        XCTAssertEqual(module.name, "push-apns")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockAPNsPushProvider()
        bridge.register(PushAPNsModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"push-apns","action":"getToken","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["token"]?.stringValue, "apns-device-token-abc123")

        bridge.dispose()
    }
}

private final class MockAPNsPushProvider: APNsPushProvider, @unchecked Sendable {
    var token: String?
    var badgeCount: Int = 0
    var removeAllDeliveredCalled = false
    var deliveredCount: Int = 0

    init(token: String? = "apns-device-token-abc123") {
        self.token = token
    }

    func getToken() async throws -> String? {
        token
    }

    func setBadgeCount(_ count: Int) async throws {
        badgeCount = count
    }

    func getBadgeCount() async throws -> Int {
        badgeCount
    }

    func removeAllDeliveredNotifications() async throws {
        removeAllDeliveredCalled = true
    }

    func getDeliveredNotificationCount() async throws -> Int {
        deliveredCount
    }
}
