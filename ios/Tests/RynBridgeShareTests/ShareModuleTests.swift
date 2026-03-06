import XCTest
@testable import RynBridge
@testable import RynBridgeShare

final class ShareModuleTests: XCTestCase {
    func testShare() async throws {
        let provider = MockShareProvider()
        let module = ShareModule(provider: provider)
        let handler = module.actions["share"]!

        let result = try await handler(["text": .string("Hello"), "url": .string("https://example.com"), "title": .string("Title")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastShareText, "Hello")
        XCTAssertEqual(provider.lastShareURL, "https://example.com")
        XCTAssertEqual(provider.lastShareTitle, "Title")
    }

    func testShareFile() async throws {
        let provider = MockShareProvider()
        let module = ShareModule(provider: provider)
        let handler = module.actions["shareFile"]!

        let result = try await handler(["filePath": .string("/tmp/file.pdf"), "mimeType": .string("application/pdf")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastShareFilePath, "/tmp/file.pdf")
        XCTAssertEqual(provider.lastShareFileMimeType, "application/pdf")
    }

    func testCopyToClipboard() async throws {
        let provider = MockShareProvider()
        let module = ShareModule(provider: provider)
        let handler = module.actions["copyToClipboard"]!

        let result = try await handler(["text": .string("copied text")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastClipboardText, "copied text")
    }

    func testReadClipboard() async throws {
        let provider = MockShareProvider()
        let module = ShareModule(provider: provider)
        let handler = module.actions["readClipboard"]!

        let result = try await handler([:])
        XCTAssertEqual(result["text"]?.stringValue, "clipboard content")
    }

    func testCanShare() async throws {
        let provider = MockShareProvider()
        let module = ShareModule(provider: provider)
        let handler = module.actions["canShare"]!

        let result = try await handler([:])
        XCTAssertEqual(result["canShare"]?.boolValue, true)
    }

    func testModuleNameAndVersion() {
        let provider = MockShareProvider()
        let module = ShareModule(provider: provider)
        XCTAssertEqual(module.name, "share")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockShareProvider: ShareProvider, @unchecked Sendable {
    var lastShareText: String?
    var lastShareURL: String?
    var lastShareTitle: String?
    var lastShareFilePath: String?
    var lastShareFileMimeType: String?
    var lastClipboardText: String?

    func share(text: String?, url: String?, title: String?) async throws -> Bool {
        lastShareText = text
        lastShareURL = url
        lastShareTitle = title
        return true
    }

    func shareFile(filePath: String, mimeType: String) async throws -> Bool {
        lastShareFilePath = filePath
        lastShareFileMimeType = mimeType
        return true
    }

    func copyToClipboard(text: String) async throws {
        lastClipboardText = text
    }

    func readClipboard() async throws -> String? {
        "clipboard content"
    }

    func canShare() async throws -> Bool {
        true
    }
}
