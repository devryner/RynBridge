import XCTest
@testable import RynBridge
@testable import RynBridgeAnalytics

final class AnalyticsModuleTests: XCTestCase {
    func testLogEvent() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["logEvent"]!

        let result = try await handler([
            "name": .string("button_click"),
            "params": .dictionary(["screen": .string("home"), "index": .int(3)]),
        ])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastEventName, "button_click")
        XCTAssertEqual(provider.lastEventParams?["screen"]?.stringValue, "home")
        XCTAssertEqual(provider.lastEventParams?["index"]?.intValue, 3)
    }

    func testLogEventWithoutParams() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["logEvent"]!

        let result = try await handler(["name": .string("app_open")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastEventName, "app_open")
        XCTAssertTrue(provider.lastEventParams?.isEmpty ?? true)
    }

    func testSetUserProperty() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["setUserProperty"]!

        let result = try await handler(["key": .string("plan"), "value": .string("premium")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastPropertyKey, "plan")
        XCTAssertEqual(provider.lastPropertyValue, "premium")
    }

    func testSetUserId() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["setUserId"]!

        let result = try await handler(["userId": .string("user-42")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastUserId, "user-42")
    }

    func testSetScreen() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["setScreen"]!

        let result = try await handler(["name": .string("home")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastScreenName, "home")
    }

    func testResetUser() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["resetUser"]!

        let result = try await handler([:])
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(provider.resetUserCalled)
    }

    func testSetEnabled() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["setEnabled"]!

        let result = try await handler(["enabled": .bool(true)])
        XCTAssertEqual(result["enabled"]?.boolValue, true)
        XCTAssertEqual(provider.lastSetEnabledValue, true)
    }

    func testIsEnabled() async throws {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        let handler = module.actions["isEnabled"]!

        let result = try await handler([:])
        XCTAssertEqual(result["enabled"]?.boolValue, true)
    }

    func testModuleNameAndVersion() {
        let provider = MockAnalyticsProvider()
        let module = AnalyticsModule(provider: provider)
        XCTAssertEqual(module.name, "analytics")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockAnalyticsProvider: AnalyticsProvider, @unchecked Sendable {
    var lastEventName: String?
    var lastEventParams: [String: AnyCodable]?
    var lastPropertyKey: String?
    var lastPropertyValue: String?
    var lastUserId: String?
    var lastScreenName: String?
    var resetUserCalled = false
    var lastSetEnabledValue: Bool?

    func logEvent(name: String, params: [String: AnyCodable]) {
        lastEventName = name
        lastEventParams = params
    }

    func setUserProperty(key: String, value: String) {
        lastPropertyKey = key
        lastPropertyValue = value
    }

    func setUserId(_ userId: String) {
        lastUserId = userId
    }

    func setScreen(name: String) {
        lastScreenName = name
    }

    func resetUser() {
        resetUserCalled = true
    }

    func setEnabled(_ enabled: Bool) async throws -> Bool {
        lastSetEnabledValue = enabled
        return enabled
    }

    func isEnabled() async throws -> Bool {
        true
    }
}
