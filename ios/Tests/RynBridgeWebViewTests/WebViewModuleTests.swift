import XCTest
@testable import RynBridge
@testable import RynBridgeWebView

final class WebViewModuleTests: XCTestCase {
    func testOpen() async throws {
        let provider = MockWebViewProvider()
        let module = WebViewModule(provider: provider)
        let handler = module.actions["open"]!

        let result = try await handler([
            "url": .string("https://example.com"),
            "title": .string("Example"),
            "style": .string("fullScreen"),
            "allowedOrigins": .array([.string("https://example.com")]),
        ])
        XCTAssertEqual(result["webviewId"]?.stringValue, "wv-123")
        XCTAssertEqual(provider.lastOpenOptions?.url, "https://example.com")
        XCTAssertEqual(provider.lastOpenOptions?.title, "Example")
        XCTAssertEqual(provider.lastOpenOptions?.style, "fullScreen")
        XCTAssertEqual(provider.lastOpenOptions?.allowedOrigins, ["https://example.com"])
    }

    func testClose() async throws {
        let provider = MockWebViewProvider()
        let module = WebViewModule(provider: provider)
        let handler = module.actions["close"]!

        let result = try await handler(["webviewId": .string("wv-123")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastClosedWebviewId, "wv-123")
    }

    func testSendMessage() async throws {
        let provider = MockWebViewProvider()
        let module = WebViewModule(provider: provider)
        let handler = module.actions["sendMessage"]!

        let result = try await handler([
            "targetId": .string("wv-123"),
            "data": .dictionary(["key": .string("value")]),
        ])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastSendMessageTargetId, "wv-123")
        XCTAssertEqual(provider.lastSendMessageData?["key"]?.stringValue, "value")
    }

    func testPostEvent() async throws {
        let provider = MockWebViewProvider()
        let module = WebViewModule(provider: provider)
        let handler = module.actions["postEvent"]!

        let result = try await handler([
            "targetId": .string("wv-123"),
            "event": .string("customEvent"),
            "data": .dictionary(["info": .string("test")]),
        ])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastPostEventTargetId, "wv-123")
        XCTAssertEqual(provider.lastPostEventName, "customEvent")
        XCTAssertEqual(provider.lastPostEventData?["info"]?.stringValue, "test")
    }

    func testGetWebViews() async throws {
        let provider = MockWebViewProvider()
        let module = WebViewModule(provider: provider)
        let handler = module.actions["getWebViews"]!

        let result = try await handler([:])
        let webviews = result["webviews"]?.arrayValue
        XCTAssertNotNil(webviews)
        XCTAssertEqual(webviews?.count, 1)
        let first = webviews?.first?.dictionaryValue
        XCTAssertEqual(first?["webviewId"]?.stringValue, "wv-123")
        XCTAssertEqual(first?["url"]?.stringValue, "https://example.com")
        XCTAssertEqual(first?["title"]?.stringValue, "Example")
    }

    func testSetResult() async throws {
        let provider = MockWebViewProvider()
        let module = WebViewModule(provider: provider)
        let handler = module.actions["setResult"]!

        let result = try await handler(["data": .dictionary(["status": .string("done")])])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastSetResultData?["status"]?.stringValue, "done")
    }

    func testModuleNameAndVersion() {
        let provider = MockWebViewProvider()
        let module = WebViewModule(provider: provider)
        XCTAssertEqual(module.name, "webview")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockWebViewProvider: WebViewProvider, @unchecked Sendable {
    var lastOpenOptions: OpenOptions?
    var lastClosedWebviewId: String?
    var lastSendMessageTargetId: String?
    var lastSendMessageData: [String: AnyCodable]?
    var lastPostEventTargetId: String?
    var lastPostEventName: String?
    var lastPostEventData: [String: AnyCodable]?
    var lastSetResultData: [String: AnyCodable]?

    func open(options: OpenOptions) async throws -> OpenResult {
        lastOpenOptions = options
        return OpenResult(webviewId: "wv-123")
    }

    func close(webviewId: String) async throws {
        lastClosedWebviewId = webviewId
    }

    func sendMessage(targetId: String, data: [String: AnyCodable]) async throws {
        lastSendMessageTargetId = targetId
        lastSendMessageData = data
    }

    func postEvent(targetId: String, event: String, data: [String: AnyCodable]?) {
        lastPostEventTargetId = targetId
        lastPostEventName = event
        lastPostEventData = data
    }

    func getWebViews() async throws -> GetWebViewsResult {
        GetWebViewsResult(webviews: [
            WebViewInfo(webviewId: "wv-123", url: "https://example.com", title: "Example"),
        ])
    }

    func setResult(data: [String: AnyCodable]) {
        lastSetResultData = data
    }
}
