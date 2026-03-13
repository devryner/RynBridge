import Foundation
import RynBridge

public struct WebViewModule: BridgeModule, Sendable {
    public let name = "webview"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: WebViewProvider) {
        actions = [
            "open": { payload in
                guard let url = payload["url"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: url")
                }
                let title = payload["title"]?.stringValue
                let style = payload["style"]?.stringValue ?? "modal"
                let allowedOrigins: [String]
                if let arr = payload["allowedOrigins"]?.arrayValue {
                    allowedOrigins = arr.compactMap { $0.stringValue }
                } else {
                    allowedOrigins = []
                }
                let options = OpenOptions(
                    url: url,
                    title: title,
                    style: style,
                    allowedOrigins: allowedOrigins
                )
                let result = try await provider.open(options: options)
                return result.toPayload()
            },
            "close": { payload in
                guard let webviewId = payload["webviewId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: webviewId")
                }
                try await provider.close(webviewId: webviewId)
                return [:]
            },
            "sendMessage": { payload in
                guard let targetId = payload["targetId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: targetId")
                }
                guard let data = payload["data"]?.dictionaryValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: data")
                }
                try await provider.sendMessage(targetId: targetId, data: data)
                return [:]
            },
            "postEvent": { payload in
                guard let targetId = payload["targetId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: targetId")
                }
                guard let event = payload["event"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: event")
                }
                let data = payload["data"]?.dictionaryValue
                provider.postEvent(targetId: targetId, event: event, data: data)
                return [:]
            },
            "getWebViews": { _ in
                let result = try await provider.getWebViews()
                return result.toPayload()
            },
            "setResult": { payload in
                guard let data = payload["data"]?.dictionaryValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: data")
                }
                provider.setResult(data: data)
                return [:]
            },
        ]
    }
}

#if canImport(UIKit)
extension WebViewModule {
    public init() {
        self.init(provider: DefaultWebViewProvider())
    }
}
#endif
