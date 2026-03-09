#if canImport(UIKit) && canImport(WebKit)
import Foundation
import UIKit
import WebKit
import RynBridge

public final class DefaultWebViewProvider: WebViewProvider, @unchecked Sendable {
    private let queue = DispatchQueue(label: "io.rynbridge.webview")
    private var webviews: [String: WKWebView] = [:]
    private var webviewControllers: [String: UIViewController] = [:]
    private var resultData: [String: AnyCodable]?

    public init() {}

    public func open(options: OpenOptions) async throws -> OpenResult {
        return await MainActor.run {
            let webviewId = UUID().uuidString
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.allowsBackForwardNavigationGestures = true

            guard let url = URL(string: options.url) else {
                return OpenResult(webviewId: webviewId)
            }

            webView.load(URLRequest(url: url))

            let vc = UIViewController()
            vc.view = webView
            vc.title = options.title ?? ""
            vc.view.backgroundColor = .systemBackground

            // Add a close button
            let navVC = UINavigationController(rootViewController: vc)
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: nil,
                action: nil
            )

            let closeAction = UIAction { [weak navVC] _ in
                navVC?.dismiss(animated: true)
            }
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: closeAction)

            switch options.style {
            case "fullScreen":
                navVC.modalPresentationStyle = .fullScreen
            case "pageSheet":
                navVC.modalPresentationStyle = .pageSheet
            case "formSheet":
                navVC.modalPresentationStyle = .formSheet
            default:
                navVC.modalPresentationStyle = .automatic
            }

            self.queue.sync {
                self.webviews[webviewId] = webView
                self.webviewControllers[webviewId] = navVC
            }

            if let topVC = Self.topViewController() {
                topVC.present(navVC, animated: true)
            }

            return OpenResult(webviewId: webviewId)
        }
    }

    public func close(webviewId: String) async throws {
        await MainActor.run {
            let vc = self.queue.sync { self.webviewControllers.removeValue(forKey: webviewId) }
            self.queue.sync { _ = self.webviews.removeValue(forKey: webviewId) }
            vc?.dismiss(animated: true)
        }
    }

    public func sendMessage(targetId: String, data: [String: AnyCodable]) async throws {
        guard let webView = queue.sync(execute: { webviews[targetId] }) else {
            throw RynBridgeError(code: .unknown, message: "WebView not found: \(targetId)")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let jsonData = try encoder.encode(data)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw RynBridgeError(code: .serializationError, message: "Failed to serialize message")
        }
        let escaped = jsonString.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        let js = "window.postMessage(\(escaped), '*')"
        await MainActor.run {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    public func postEvent(targetId: String, event: String, data: [String: AnyCodable]?) {
        guard let webView = queue.sync(execute: { webviews[targetId] }) else { return }
        Task { @MainActor in
            let dataJSON: String
            if let data {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(data), let str = String(data: encoded, encoding: .utf8) {
                    dataJSON = str
                } else {
                    dataJSON = "{}"
                }
            } else {
                dataJSON = "null"
            }
            let js = "window.dispatchEvent(new CustomEvent('\(event)', {detail: \(dataJSON)}))"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    public func getWebViews() async throws -> GetWebViewsResult {
        let infos: [WebViewInfo] = await MainActor.run {
            let wvs = self.queue.sync { Array(self.webviews) }
            return wvs.compactMap { (id, webView) in
                let url = webView.url?.absoluteString ?? ""
                let title = webView.title
                return WebViewInfo(webviewId: id, url: url, title: title)
            }
        }
        return GetWebViewsResult(webviews: infos)
    }

    public func setResult(data: [String: AnyCodable]) {
        queue.sync {
            resultData = .dictionary(data)
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
#endif
