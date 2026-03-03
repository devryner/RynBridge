import SwiftUI
import WebKit
import RynBridge
import RynBridgeDevice
import RynBridgeStorage
import RynBridgeSecureStorage
import RynBridgeUI

struct BridgeWebView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isInspectable = true

        // Set up bridge
        let transport = WKWebViewTransport(webView: webView)
        let bridge = RynBridge(transport: transport)

        // Register modules with real providers
        bridge.register(DeviceModule(provider: DefaultDeviceInfoProvider()))
        bridge.register(StorageModule(provider: UserDefaultsStorageProvider()))
        bridge.register(SecureStorageModule(provider: KeychainSecureStorageProvider()))
        bridge.register(RynBridgeUI.UIModule(provider: DefaultUIProvider()))

        context.coordinator.bridge = bridge

        // Load the web playground
        if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator {
        var bridge: RynBridge?

        deinit {
            bridge?.dispose()
        }
    }
}
