import Foundation
import CryptoKit
import RynBridge

public final class DefaultCryptoProvider: CryptoProvider, @unchecked Sendable {
    private var privateKey: Curve25519.KeyAgreement.PrivateKey
    private var symmetricKey: SymmetricKey?
    private var keyCreatedAt: Date

    public init() {
        self.privateKey = Curve25519.KeyAgreement.PrivateKey()
        self.keyCreatedAt = Date()
    }

    public func generateKeyPair() async throws -> String {
        privateKey = Curve25519.KeyAgreement.PrivateKey()
        keyCreatedAt = Date()
        symmetricKey = nil
        return privateKey.publicKey.rawRepresentation.base64EncodedString()
    }

    public func performKeyExchange(remotePublicKey: String) async throws -> Bool {
        guard let remoteKeyData = Data(base64Encoded: remotePublicKey) else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid base64 public key")
        }
        let remoteKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: remoteKeyData)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: remoteKey)
        symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("RynBridge".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        return true
    }

    public func encrypt(data: String, associatedData: String?) async throws -> EncryptResult {
        guard let key = symmetricKey else {
            throw RynBridgeError(code: .unknown, message: "Key exchange not performed. Call performKeyExchange first.")
        }
        let plaintext = Data(data.utf8)
        let aad = associatedData.map { Data($0.utf8) }
        let sealedBox: AES.GCM.SealedBox
        if let aad {
            sealedBox = try AES.GCM.seal(plaintext, using: key, authenticating: aad)
        } else {
            sealedBox = try AES.GCM.seal(plaintext, using: key)
        }
        return EncryptResult(
            ciphertext: sealedBox.ciphertext.base64EncodedString(),
            iv: sealedBox.nonce.withUnsafeBytes { Data($0) }.base64EncodedString(),
            tag: sealedBox.tag.base64EncodedString()
        )
    }

    public func decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?) async throws -> String {
        guard let key = symmetricKey else {
            throw RynBridgeError(code: .unknown, message: "Key exchange not performed. Call performKeyExchange first.")
        }
        guard let ciphertextData = Data(base64Encoded: ciphertext),
              let ivData = Data(base64Encoded: iv),
              let tagData = Data(base64Encoded: tag) else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid base64 encoded data")
        }
        let nonce = try AES.GCM.Nonce(data: ivData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertextData, tag: tagData)
        let decryptedData: Data
        let aad = associatedData.map { Data($0.utf8) }
        if let aad {
            decryptedData = try AES.GCM.open(sealedBox, using: key, authenticating: aad)
        } else {
            decryptedData = try AES.GCM.open(sealedBox, using: key)
        }
        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw RynBridgeError(code: .unknown, message: "Failed to decode decrypted data as UTF-8")
        }
        return plaintext
    }

    public func getStatus() async throws -> CryptoStatus {
        let formatter = ISO8601DateFormatter()
        return CryptoStatus(
            initialized: symmetricKey != nil,
            keyCreatedAt: formatter.string(from: keyCreatedAt),
            algorithm: "AES-256-GCM"
        )
    }

    public func rotateKeys() async throws -> String {
        privateKey = Curve25519.KeyAgreement.PrivateKey()
        keyCreatedAt = Date()
        symmetricKey = nil
        return privateKey.publicKey.rawRepresentation.base64EncodedString()
    }
}
