import XCTest
@testable import RynBridge
@testable import RynBridgeCrypto

final class CryptoModuleTests: XCTestCase {
    func testGenerateKeyPair() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["generateKeyPair"]!

        let result = try await handler([:])
        XCTAssertEqual(result["publicKey"]?.stringValue, "mock-public-key-base64")
    }

    func testPerformKeyExchange() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["performKeyExchange"]!

        let result = try await handler(["remotePublicKey": .string("remote-key-abc")])
        XCTAssertEqual(result["sessionEstablished"]?.boolValue, true)
        XCTAssertEqual(provider.lastRemotePublicKey, "remote-key-abc")
    }

    func testEncrypt() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["encrypt"]!

        let result = try await handler([
            "data": .string("hello world"),
            "associatedData": .string("metadata"),
        ])
        XCTAssertEqual(result["ciphertext"]?.stringValue, "encrypted-data-xyz")
        XCTAssertEqual(result["iv"]?.stringValue, "iv-123")
        XCTAssertEqual(result["tag"]?.stringValue, "tag-456")
        XCTAssertEqual(provider.lastEncryptData, "hello world")
        XCTAssertEqual(provider.lastEncryptAssociatedData, "metadata")
    }

    func testEncryptWithoutAssociatedData() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["encrypt"]!

        _ = try await handler(["data": .string("secret")])
        XCTAssertNil(provider.lastEncryptAssociatedData)
    }

    func testDecrypt() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["decrypt"]!

        let result = try await handler([
            "ciphertext": .string("encrypted-data-xyz"),
            "iv": .string("iv-123"),
            "tag": .string("tag-456"),
            "associatedData": .string("metadata"),
        ])
        XCTAssertEqual(result["plaintext"]?.stringValue, "decrypted-plaintext")
        XCTAssertEqual(provider.lastDecryptCiphertext, "encrypted-data-xyz")
        XCTAssertEqual(provider.lastDecryptIv, "iv-123")
        XCTAssertEqual(provider.lastDecryptTag, "tag-456")
        XCTAssertEqual(provider.lastDecryptAssociatedData, "metadata")
    }

    func testDecryptWithoutAssociatedData() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["decrypt"]!

        _ = try await handler([
            "ciphertext": .string("data"),
            "iv": .string("iv"),
            "tag": .string("tag"),
        ])
        XCTAssertNil(provider.lastDecryptAssociatedData)
    }

    func testGetStatus() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["getStatus"]!

        let result = try await handler([:])
        XCTAssertEqual(result["initialized"]?.boolValue, true)
        XCTAssertEqual(result["keyCreatedAt"]?.stringValue, "2026-01-01T00:00:00Z")
        XCTAssertEqual(result["algorithm"]?.stringValue, "AES-256-GCM")
    }

    func testRotateKeys() async throws {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        let handler = module.actions["rotateKeys"]!

        let result = try await handler([:])
        XCTAssertEqual(result["publicKey"]?.stringValue, "new-public-key-base64")
        XCTAssertTrue(provider.rotateKeysCalled)
    }

    func testModuleNameAndVersion() {
        let provider = MockCryptoProvider()
        let module = CryptoModule(provider: provider)
        XCTAssertEqual(module.name, "crypto")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockCryptoProvider()
        bridge.register(CryptoModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"crypto","action":"getStatus","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["algorithm"]?.stringValue, "AES-256-GCM")

        bridge.dispose()
    }
}

private final class MockCryptoProvider: CryptoProvider, @unchecked Sendable {
    var lastRemotePublicKey: String?
    var lastEncryptData: String?
    var lastEncryptAssociatedData: String?
    var lastDecryptCiphertext: String?
    var lastDecryptIv: String?
    var lastDecryptTag: String?
    var lastDecryptAssociatedData: String?
    var rotateKeysCalled = false

    func generateKeyPair() async throws -> String {
        "mock-public-key-base64"
    }

    func performKeyExchange(remotePublicKey: String) async throws -> Bool {
        lastRemotePublicKey = remotePublicKey
        return true
    }

    func encrypt(data: String, associatedData: String?) async throws -> EncryptResult {
        lastEncryptData = data
        lastEncryptAssociatedData = associatedData
        return EncryptResult(ciphertext: "encrypted-data-xyz", iv: "iv-123", tag: "tag-456")
    }

    func decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?) async throws -> String {
        lastDecryptCiphertext = ciphertext
        lastDecryptIv = iv
        lastDecryptTag = tag
        lastDecryptAssociatedData = associatedData
        return "decrypted-plaintext"
    }

    func getStatus() async throws -> CryptoStatus {
        CryptoStatus(initialized: true, keyCreatedAt: "2026-01-01T00:00:00Z", algorithm: "AES-256-GCM")
    }

    func rotateKeys() async throws -> String {
        rotateKeysCalled = true
        return "new-public-key-base64"
    }
}
