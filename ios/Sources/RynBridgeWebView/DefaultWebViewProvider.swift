#if canImport(UIKit)
import Foundation
import RynBridge

public final class DefaultWebViewProvider: WebViewProvider, @unchecked Sendable {
    public init() {}

    public func open(options: OpenOptions) async throws -> OpenResult {
        throw RynBridgeError(
            code: .unknown,
            message: "open requires a custom WebViewProvider implementation with UIViewController context"
        )
    }

    public func close(webviewId: String) async throws {
        throw RynBridgeError(
            code: .unknown,
            message: "close requires a custom WebViewProvider implementation with UIViewController context"
        )
    }

    public func sendMessage(targetId: String, data: [String: AnyCodable]) async throws {
        throw RynBridgeError(
            code: .unknown,
            message: "sendMessage requires a custom WebViewProvider implementation"
        )
    }

    public func postEvent(targetId: String, event: String, data: [String: AnyCodable]?) {
        // No-op: requires a custom WebViewProvider implementation
    }

    public func getWebViews() async throws -> GetWebViewsResult {
        return GetWebViewsResult(webviews: [])
    }

    public func setResult(data: [String: AnyCodable]) {
        // No-op: requires a custom WebViewProvider implementation
    }
}
#endif
