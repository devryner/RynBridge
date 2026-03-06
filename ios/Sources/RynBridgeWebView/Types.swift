import Foundation
import RynBridge

public struct OpenOptions: Sendable {
    public let url: String
    public let title: String?
    public let style: String
    public let allowedOrigins: [String]

    public init(url: String, title: String? = nil, style: String = "modal", allowedOrigins: [String] = []) {
        self.url = url
        self.title = title
        self.style = style
        self.allowedOrigins = allowedOrigins
    }
}

public struct OpenResult: Sendable {
    public let webviewId: String

    public init(webviewId: String) {
        self.webviewId = webviewId
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "webviewId": .string(webviewId),
        ]
    }
}

public struct WebViewInfo: Sendable {
    public let webviewId: String
    public let url: String
    public let title: String?

    public init(webviewId: String, url: String, title: String? = nil) {
        self.webviewId = webviewId
        self.url = url
        self.title = title
    }

    public func toPayload() -> [String: AnyCodable] {
        var result: [String: AnyCodable] = [
            "webviewId": .string(webviewId),
            "url": .string(url),
        ]
        if let title {
            result["title"] = .string(title)
        }
        return result
    }
}

public struct GetWebViewsResult: Sendable {
    public let webviews: [WebViewInfo]

    public init(webviews: [WebViewInfo]) {
        self.webviews = webviews
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "webviews": .array(webviews.map { wv in
                .dictionary(wv.toPayload())
            }),
        ]
    }
}

public protocol WebViewProvider: Sendable {
    func open(options: OpenOptions) async throws -> OpenResult
    func close(webviewId: String) async throws
    func sendMessage(targetId: String, data: [String: AnyCodable]) async throws
    func postEvent(targetId: String, event: String, data: [String: AnyCodable]?)
    func getWebViews() async throws -> GetWebViewsResult
    func setResult(data: [String: AnyCodable])
}
