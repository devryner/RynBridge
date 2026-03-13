import Foundation
import RynBridge

public struct CryptoModule: BridgeModule, Sendable {
    public let name = "crypto"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init() {
        self.init(provider: DefaultCryptoProvider())
    }

    public init(provider: CryptoProvider) {
        actions = [
            "generateKeyPair": { _ in
                let publicKey = try await provider.generateKeyPair()
                return ["publicKey": .string(publicKey)]
            },
            "performKeyExchange": { payload in
                guard let remotePublicKey = payload["remotePublicKey"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: remotePublicKey")
                }
                let established = try await provider.performKeyExchange(remotePublicKey: remotePublicKey)
                return ["sessionEstablished": .bool(established)]
            },
            "encrypt": { payload in
                guard let data = payload["data"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: data")
                }
                let associatedData = payload["associatedData"]?.stringValue
                let result = try await provider.encrypt(data: data, associatedData: associatedData)
                return result.toPayload()
            },
            "decrypt": { payload in
                guard let ciphertext = payload["ciphertext"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: ciphertext")
                }
                guard let iv = payload["iv"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: iv")
                }
                guard let tag = payload["tag"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: tag")
                }
                let associatedData = payload["associatedData"]?.stringValue
                let plaintext = try await provider.decrypt(ciphertext: ciphertext, iv: iv, tag: tag, associatedData: associatedData)
                return ["plaintext": .string(plaintext)]
            },
            "getStatus": { _ in
                let status = try await provider.getStatus()
                return status.toPayload()
            },
            "rotateKeys": { _ in
                let publicKey = try await provider.rotateKeys()
                return ["publicKey": .string(publicKey)]
            },
        ]
    }
}
