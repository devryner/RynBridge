import Foundation
import RynBridge

public struct ShareModule: BridgeModule, Sendable {
    public let name = "share"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: ShareProvider) {
        actions = [
            "share": { payload in
                let text = payload["text"]?.stringValue
                let url = payload["url"]?.stringValue
                let title = payload["title"]?.stringValue
                let success = try await provider.share(text: text, url: url, title: title)
                return ShareResult(success: success).toPayload()
            },
            "shareFile": { payload in
                guard let filePath = payload["filePath"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: filePath")
                }
                guard let mimeType = payload["mimeType"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: mimeType")
                }
                let success = try await provider.shareFile(filePath: filePath, mimeType: mimeType)
                return ShareResult(success: success).toPayload()
            },
            "copyToClipboard": { payload in
                guard let text = payload["text"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: text")
                }
                try await provider.copyToClipboard(text: text)
                return [:]
            },
            "readClipboard": { _ in
                let text = try await provider.readClipboard()
                return ClipboardText(text: text ?? "").toPayload()
            },
            "canShare": { _ in
                let canShare = try await provider.canShare()
                return ["canShare": .bool(canShare)]
            },
        ]
    }
}

#if canImport(UIKit)
extension ShareModule {
    public init() {
        self.init(provider: DefaultShareProvider())
    }
}
#endif
