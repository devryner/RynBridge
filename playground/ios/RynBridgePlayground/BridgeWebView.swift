import SwiftUI
import WebKit
import RynBridge
import RynBridgeDevice
import RynBridgeStorage
import RynBridgeSecureStorage
import RynBridgeUI
import RynBridgeAuth
import RynBridgePush
import RynBridgePayment
import RynBridgeMedia
import RynBridgeCrypto

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

        // Register Phase 1 modules
        bridge.register(DeviceModule(provider: DefaultDeviceInfoProvider()))
        bridge.register(StorageModule(provider: UserDefaultsStorageProvider()))
        bridge.register(SecureStorageModule(provider: KeychainSecureStorageProvider()))
        bridge.register(RynBridgeUI.UIModule(provider: DefaultUIProvider()))

        // Register Phase 2 modules (mock providers for playground)
        bridge.register(AuthModule(provider: MockAuthProvider()))
        bridge.register(PushModule(provider: MockPushProvider()))
        bridge.register(PaymentModule(provider: MockPaymentProvider()))
        bridge.register(MediaModule(provider: MockMediaProvider()))
        bridge.register(CryptoModule(provider: MockCryptoProvider()))

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

// MARK: - Mock Providers for Playground

final class MockAuthProvider: AuthProvider, @unchecked Sendable {
    private var currentToken: String?

    func login(provider: String, scopes: [String]) async throws -> LoginResult {
        let token = "mock_token_\(UUID().uuidString.prefix(8))"
        currentToken = token
        return LoginResult(
            token: token,
            refreshToken: "mock_refresh_\(UUID().uuidString.prefix(8))",
            expiresAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
            user: AuthUser(id: "user_1", email: "test@example.com", name: "Test User")
        )
    }

    func logout() async throws {
        currentToken = nil
    }

    func getToken() async throws -> TokenResult {
        return TokenResult(token: currentToken, expiresAt: currentToken != nil ? ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)) : nil)
    }

    func refreshToken() async throws -> LoginResult {
        return try await login(provider: "refresh", scopes: [])
    }

    func getUser() async throws -> AuthUser? {
        guard currentToken != nil else { return nil }
        return AuthUser(id: "user_1", email: "test@example.com", name: "Test User")
    }
}

final class MockPushProvider: PushProvider, @unchecked Sendable {
    func register() async throws -> PushRegistration {
        return PushRegistration(token: "mock_push_token_\(UUID().uuidString.prefix(8))", platform: "ios")
    }

    func unregister() async throws {}

    func getToken() async throws -> String? {
        return "mock_push_token"
    }

    func requestPermission() async throws -> Bool {
        return true
    }

    func getPermissionStatus() async throws -> PushPermissionStatus {
        return PushPermissionStatus(status: "granted")
    }
}

final class MockPaymentProvider: PaymentProvider, @unchecked Sendable {
    func getProducts(productIds: [String]) async throws -> [Product] {
        return productIds.map { id in
            Product(
                id: id,
                title: id == "premium_monthly" ? "Premium Monthly" : "Premium Yearly",
                description: "Unlock all features",
                price: id == "premium_monthly" ? "9.99" : "99.99",
                currency: "USD"
            )
        }
    }

    func purchase(productId: String, quantity: Int) async throws -> RynBridgePayment.PurchaseResult {
        return RynBridgePayment.PurchaseResult(
            transactionId: "txn_\(UUID().uuidString.prefix(8))",
            productId: productId,
            receipt: "mock_receipt_data"
        )
    }

    func restorePurchases() async throws -> [Transaction] {
        return [
            Transaction(
                transactionId: "txn_restored_1",
                productId: "premium_monthly",
                purchaseDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
                receipt: "mock_receipt_restored"
            )
        ]
    }

    func finishTransaction(transactionId: String) async throws {}
}

final class MockMediaProvider: MediaProvider, @unchecked Sendable {
    func playAudio(source: String, loop: Bool, volume: Double) async throws -> String {
        return "player_\(UUID().uuidString.prefix(8))"
    }

    func pauseAudio(playerId: String) async throws {}

    func stopAudio(playerId: String) async throws {}

    func getAudioStatus(playerId: String) async throws -> AudioStatus {
        return AudioStatus(position: 30.0, duration: 180.0, isPlaying: true)
    }

    func startRecording(format: String, quality: String) async throws -> String {
        return "rec_\(UUID().uuidString.prefix(8))"
    }

    func stopRecording(recordingId: String) async throws -> RecordingResult {
        return RecordingResult(filePath: "/tmp/\(recordingId).m4a", duration: 5.2, size: 52400)
    }

    func pickMedia(type: String, multiple: Bool) async throws -> [MediaFile] {
        return [
            MediaFile(name: "photo.jpg", path: "/tmp/photo.jpg", mimeType: "image/jpeg", size: 1024000)
        ]
    }
}

final class MockCryptoProvider: CryptoProvider, @unchecked Sendable {
    func generateKeyPair() async throws -> String {
        return "mock_public_key_\(UUID().uuidString.prefix(16))"
    }

    func performKeyExchange(remotePublicKey: String) async throws -> Bool {
        return true
    }

    func encrypt(data: String, associatedData: String?) async throws -> RynBridgeCrypto.EncryptResult {
        return RynBridgeCrypto.EncryptResult(
            ciphertext: Data(data.utf8).base64EncodedString(),
            iv: UUID().uuidString.prefix(24).description,
            tag: UUID().uuidString.prefix(32).description
        )
    }

    func decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?) async throws -> String {
        if let data = Data(base64Encoded: ciphertext), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "decrypted_data"
    }

    func getStatus() async throws -> RynBridgeCrypto.CryptoStatus {
        return RynBridgeCrypto.CryptoStatus(
            initialized: true,
            keyCreatedAt: ISO8601DateFormatter().string(from: Date()),
            algorithm: "AES-256-GCM"
        )
    }

    func rotateKeys() async throws -> String {
        return "mock_rotated_key_\(UUID().uuidString.prefix(16))"
    }
}
