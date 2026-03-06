import Foundation
import RynBridge

public struct ShareResult: Sendable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "success": .bool(success),
        ]
    }
}

public struct ClipboardText: Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "text": .string(text),
        ]
    }
}

public protocol ShareProvider: Sendable {
    func share(text: String?, url: String?, title: String?) async throws -> Bool
    func shareFile(filePath: String, mimeType: String) async throws -> Bool
    func copyToClipboard(text: String) async throws
    func readClipboard() async throws -> String?
    func canShare() async throws -> Bool
}
