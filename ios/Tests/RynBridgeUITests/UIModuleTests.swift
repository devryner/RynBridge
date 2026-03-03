import XCTest
@testable import RynBridge
@testable import RynBridgeUI

final class UIModuleTests: XCTestCase {
    func testShowAlert() async throws {
        let provider = MockUIProvider()
        let module = UIModule(provider: provider)
        let handler = module.actions["showAlert"]!

        let result = try await handler([
            "title": "Hello",
            "message": "World",
            "buttonText": "OK",
        ])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastAlertTitle, "Hello")
        XCTAssertEqual(provider.lastAlertMessage, "World")
        XCTAssertEqual(provider.lastAlertButtonText, "OK")
    }

    func testShowAlertDefaults() async throws {
        let provider = MockUIProvider()
        let module = UIModule(provider: provider)
        let handler = module.actions["showAlert"]!

        _ = try await handler(["title": "T", "message": "M"])
        XCTAssertEqual(provider.lastAlertButtonText, "OK")
    }

    func testShowConfirm() async throws {
        let provider = MockUIProvider()
        provider.confirmResult = true
        let module = UIModule(provider: provider)
        let handler = module.actions["showConfirm"]!

        let result = try await handler([
            "title": "Delete?",
            "message": "Are you sure?",
            "confirmText": "Yes",
            "cancelText": "No",
        ])
        XCTAssertEqual(result["confirmed"]?.boolValue, true)
        XCTAssertEqual(provider.lastConfirmTitle, "Delete?")
    }

    func testShowConfirmDefaults() async throws {
        let provider = MockUIProvider()
        let module = UIModule(provider: provider)
        let handler = module.actions["showConfirm"]!

        _ = try await handler(["title": "T", "message": "M"])
        XCTAssertEqual(provider.lastConfirmConfirmText, "Confirm")
        XCTAssertEqual(provider.lastConfirmCancelText, "Cancel")
    }

    func testShowToast() async throws {
        let provider = MockUIProvider()
        let module = UIModule(provider: provider)
        let handler = module.actions["showToast"]!

        let result = try await handler(["message": "Saved!", "duration": .double(3.0)])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastToastMessage, "Saved!")
        XCTAssertEqual(provider.lastToastDuration, 3.0)
    }

    func testShowToastDefaultDuration() async throws {
        let provider = MockUIProvider()
        let module = UIModule(provider: provider)
        let handler = module.actions["showToast"]!

        _ = try await handler(["message": "Hi"])
        XCTAssertEqual(provider.lastToastDuration, 2.0)
    }

    func testShowActionSheet() async throws {
        let provider = MockUIProvider()
        provider.actionSheetResult = 1
        let module = UIModule(provider: provider)
        let handler = module.actions["showActionSheet"]!

        let result = try await handler([
            "title": "Choose",
            "options": .array(["A", "B", "C"]),
        ])
        XCTAssertEqual(result["selectedIndex"]?.intValue, 1)
        XCTAssertEqual(provider.lastActionSheetOptions, ["A", "B", "C"])
    }

    func testSetStatusBar() async throws {
        let provider = MockUIProvider()
        let module = UIModule(provider: provider)
        let handler = module.actions["setStatusBar"]!

        let result = try await handler(["style": "light", "hidden": .bool(true)])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastStatusBarStyle, "light")
        XCTAssertEqual(provider.lastStatusBarHidden, true)
    }

    func testModuleNameAndVersion() {
        let provider = MockUIProvider()
        let module = UIModule(provider: provider)
        XCTAssertEqual(module.name, "ui")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockUIProvider()
        bridge.register(UIModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"ui","action":"showToast","payload":{"message":"Hello"},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.status, .success)

        bridge.dispose()
    }
}

private final class MockUIProvider: UIProvider, @unchecked Sendable {
    var lastAlertTitle: String?
    var lastAlertMessage: String?
    var lastAlertButtonText: String?
    var lastConfirmTitle: String?
    var lastConfirmConfirmText: String?
    var lastConfirmCancelText: String?
    var confirmResult = false
    var lastToastMessage: String?
    var lastToastDuration: Double?
    var lastActionSheetTitle: String?
    var lastActionSheetOptions: [String]?
    var actionSheetResult = 0
    var lastStatusBarStyle: String?
    var lastStatusBarHidden: Bool?

    func showAlert(title: String, message: String, buttonText: String) async {
        lastAlertTitle = title
        lastAlertMessage = message
        lastAlertButtonText = buttonText
    }

    func showConfirm(title: String, message: String, confirmText: String, cancelText: String) async -> Bool {
        lastConfirmTitle = title
        lastConfirmConfirmText = confirmText
        lastConfirmCancelText = cancelText
        return confirmResult
    }

    func showToast(message: String, duration: Double) {
        lastToastMessage = message
        lastToastDuration = duration
    }

    func showActionSheet(title: String?, options: [String]) async -> Int {
        lastActionSheetTitle = title
        lastActionSheetOptions = options
        return actionSheetResult
    }

    func setStatusBar(style: String?, hidden: Bool?) async {
        lastStatusBarStyle = style
        lastStatusBarHidden = hidden
    }
}
