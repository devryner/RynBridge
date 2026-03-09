import XCTest
@testable import RynBridge
@testable import RynBridgePushFCM

final class PushFCMModuleTests: XCTestCase {
    func testGetToken() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["getToken"]!

        let result = try await handler([:])
        XCTAssertEqual(result["token"]?.stringValue, "fcm-token-abc123")
    }

    func testDeleteToken() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["deleteToken"]!

        let result = try await handler([:])
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(provider.deleteTokenCalled)
    }

    func testSubscribeToTopic() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["subscribeToTopic"]!

        let result = try await handler(["topic": .string("news")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.subscribedTopics, ["news"])
    }

    func testSubscribeToTopicMissingField() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["subscribeToTopic"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testUnsubscribeFromTopic() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["unsubscribeFromTopic"]!

        let result = try await handler(["topic": .string("news")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.unsubscribedTopics, ["news"])
    }

    func testGetAutoInitEnabled() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["getAutoInitEnabled"]!

        let result = try await handler([:])
        XCTAssertEqual(result["enabled"]?.boolValue, true)
    }

    func testSetAutoInitEnabled() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["setAutoInitEnabled"]!

        let result = try await handler(["enabled": .bool(false)])
        XCTAssertTrue(result.isEmpty)
        XCTAssertFalse(provider.autoInitEnabled)
    }

    func testSetAutoInitEnabledMissingField() async throws {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        let handler = module.actions["setAutoInitEnabled"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testModuleNameAndVersion() {
        let provider = MockFCMPushProvider()
        let module = PushFCMModule(provider: provider)
        XCTAssertEqual(module.name, "push-fcm")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockFCMPushProvider()
        bridge.register(PushFCMModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"push-fcm","action":"getToken","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["token"]?.stringValue, "fcm-token-abc123")

        bridge.dispose()
    }
}

private final class MockFCMPushProvider: FCMPushProvider, @unchecked Sendable {
    var deleteTokenCalled = false
    var subscribedTopics: [String] = []
    var unsubscribedTopics: [String] = []
    var autoInitEnabled = true

    func getToken() async throws -> String {
        "fcm-token-abc123"
    }

    func deleteToken() async throws {
        deleteTokenCalled = true
    }

    func subscribeToTopic(_ topic: String) async throws {
        subscribedTopics.append(topic)
    }

    func unsubscribeFromTopic(_ topic: String) async throws {
        unsubscribedTopics.append(topic)
    }

    func getAutoInitEnabled() async throws -> Bool {
        autoInitEnabled
    }

    func setAutoInitEnabled(_ enabled: Bool) async throws {
        autoInitEnabled = enabled
    }
}
