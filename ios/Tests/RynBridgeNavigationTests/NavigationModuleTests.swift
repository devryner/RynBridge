import XCTest
@testable import RynBridge
@testable import RynBridgeNavigation

final class NavigationModuleTests: XCTestCase {
    func testPush() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["push"]!

        let result = try await handler(["screen": .string("detail"), "params": .dictionary(["id": .string("123")])])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastPushedScreen, "detail")
    }

    func testPop() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["pop"]!

        let result = try await handler([:])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertTrue(provider.popCalled)
    }

    func testPopToRoot() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["popToRoot"]!

        let result = try await handler([:])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertTrue(provider.popToRootCalled)
    }

    func testPresent() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["present"]!

        let result = try await handler(["screen": .string("modal"), "style": .string("fullScreen")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastPresentedScreen, "modal")
        XCTAssertEqual(provider.lastPresentedStyle, "fullScreen")
    }

    func testDismiss() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["dismiss"]!

        let result = try await handler([:])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertTrue(provider.dismissCalled)
    }

    func testOpenURL() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["openURL"]!

        let result = try await handler(["url": .string("https://example.com")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastOpenedURL, "https://example.com")
    }

    func testCanOpenURL() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["canOpenURL"]!

        let result = try await handler(["url": .string("https://example.com")])
        XCTAssertEqual(result["canOpen"]?.boolValue, true)
    }

    func testGetInitialURL() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["getInitialURL"]!

        let result = try await handler([:])
        XCTAssertEqual(result["url"]?.stringValue, "myapp://launch?ref=home")
    }

    func testGetAppState() async throws {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        let handler = module.actions["getAppState"]!

        let result = try await handler([:])
        XCTAssertEqual(result["state"]?.stringValue, "active")
    }

    func testModuleNameAndVersion() {
        let provider = MockNavigationProvider()
        let module = NavigationModule(provider: provider)
        XCTAssertEqual(module.name, "navigation")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockNavigationProvider: NavigationProvider, @unchecked Sendable {
    var lastPushedScreen: String?
    var popCalled = false
    var popToRootCalled = false
    var lastPresentedScreen: String?
    var lastPresentedStyle: String?
    var dismissCalled = false
    var lastOpenedURL: String?

    func push(screen: String, params: [String: AnyCodable]?) async throws -> PopResult {
        lastPushedScreen = screen
        return PopResult(success: true)
    }

    func pop() async throws -> PopResult {
        popCalled = true
        return PopResult(success: true)
    }

    func popToRoot() async throws -> PopResult {
        popToRootCalled = true
        return PopResult(success: true)
    }

    func present(screen: String, style: String?, params: [String: AnyCodable]?) async throws -> PopResult {
        lastPresentedScreen = screen
        lastPresentedStyle = style
        return PopResult(success: true)
    }

    func dismiss() async throws -> PopResult {
        dismissCalled = true
        return PopResult(success: true)
    }

    func openURL(url: String) async throws -> OpenURLResult {
        lastOpenedURL = url
        return OpenURLResult(success: true)
    }

    func canOpenURL(url: String) async throws -> CanOpenURLResult {
        CanOpenURLResult(canOpen: true)
    }

    func getInitialURL() async throws -> InitialURLResult {
        InitialURLResult(url: "myapp://launch?ref=home")
    }

    func getAppState() async throws -> AppStateResult {
        AppStateResult(state: "active")
    }
}
