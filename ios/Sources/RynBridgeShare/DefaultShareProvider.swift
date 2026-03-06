import Foundation
import RynBridge

#if canImport(UIKit)
import UIKit

public final class DefaultShareProvider: ShareProvider, @unchecked Sendable {

    public init() {}

    public func share(text: String?, url: String?, title: String?) async throws -> Bool {
        throw RynBridgeError(code: .unknown, message: "share requires a UIViewController context. Use a custom provider for UI-based sharing.")
    }

    public func shareFile(filePath: String, mimeType: String) async throws -> Bool {
        throw RynBridgeError(code: .unknown, message: "shareFile requires a UIViewController context. Use a custom provider for UI-based sharing.")
    }

    public func copyToClipboard(text: String) async throws {
        UIPasteboard.general.string = text
    }

    public func readClipboard() async throws -> String? {
        return UIPasteboard.general.string
    }

    public func canShare() async throws -> Bool {
        return true
    }
}
#endif
