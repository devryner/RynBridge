import Foundation
import WebKit

@MainActor
public final class WKWebViewTransport: NSObject, Transport, WKScriptMessageHandler {
    private weak var webView: WKWebView?
    private var messageHandler: (@Sendable (String) -> Void)?
    private let handlerName = "RynBridge"

    public init(webView: WKWebView) {
        self.webView = webView
        super.init()
        webView.configuration.userContentController.add(self, name: handlerName)
    }

    nonisolated public func send(_ message: String) {
        let escaped = message
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")

        let js = "window.__rynbridge_receive('\(escaped)')"

        Task { @MainActor [weak self] in
            _ = try? await self?.webView?.evaluateJavaScript(js)
        }
    }

    nonisolated public func onMessage(_ handler: @escaping @Sendable (String) -> Void) {
        Task { @MainActor [weak self] in
            self?.messageHandler = handler
        }
    }

    nonisolated public func dispose() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: self.handlerName)
            self.messageHandler = nil
            self.webView = nil
        }
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == handlerName else { return }
        if let body = message.body as? String {
            messageHandler?(body)
        }
    }
}
