import Foundation
import RynBridge

public struct EncryptResult: Sendable {
    public let ciphertext: String
    public let iv: String
    public let tag: String

    public init(ciphertext: String, iv: String, tag: String) {
        self.ciphertext = ciphertext
        self.iv = iv
        self.tag = tag
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "ciphertext": .string(ciphertext),
            "iv": .string(iv),
            "tag": .string(tag),
        ]
    }
}

public struct CryptoStatus: Sendable {
    public let initialized: Bool
    public let keyCreatedAt: String?
    public let algorithm: String

    public init(initialized: Bool, keyCreatedAt: String? = nil, algorithm: String) {
        self.initialized = initialized
        self.keyCreatedAt = keyCreatedAt
        self.algorithm = algorithm
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "initialized": .bool(initialized),
            "keyCreatedAt": keyCreatedAt.map { .string($0) } ?? .null,
            "algorithm": .string(algorithm),
        ]
    }
}

public protocol CryptoProvider: Sendable {
    func generateKeyPair() async throws -> String
    func performKeyExchange(remotePublicKey: String) async throws -> Bool
    func encrypt(data: String, associatedData: String?) async throws -> EncryptResult
    func decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?) async throws -> String
    func getStatus() async throws -> CryptoStatus
    func rotateKeys() async throws -> String
}
