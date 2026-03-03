import Foundation
import RynBridge
import Security

public struct SecureStorageModule: BridgeModule, Sendable {
    public let name = "secure-storage"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: SecureStorageProvider) {
        actions = [
            "get": { payload in
                guard let key = payload["key"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: key")
                }
                let value = try provider.get(key: key)
                if let value = value {
                    return ["value": .string(value)]
                } else {
                    return ["value": .null]
                }
            },
            "set": { payload in
                guard let key = payload["key"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: key")
                }
                guard let value = payload["value"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: value")
                }
                try provider.set(key: key, value: value)
                return [:]
            },
            "remove": { payload in
                guard let key = payload["key"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: key")
                }
                try provider.remove(key: key)
                return [:]
            },
            "has": { payload in
                guard let key = payload["key"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: key")
                }
                let exists = try provider.has(key: key)
                return ["exists": .bool(exists)]
            },
        ]
    }
}

public final class KeychainSecureStorageProvider: SecureStorageProvider, @unchecked Sendable {
    private let service: String

    public init(service: String = "io.rynbridge.secure-storage") {
        self.service = service
    }

    public func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw RynBridgeError(code: .unknown, message: "Keychain read failed with status: \(status)")
        }

        return String(data: data, encoding: .utf8)
    }

    public func set(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw RynBridgeError(code: .unknown, message: "Failed to encode value as UTF-8")
        }

        // Try to update first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, add it
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw RynBridgeError(code: .unknown, message: "Keychain add failed with status: \(addStatus)")
            }
        } else if updateStatus != errSecSuccess {
            throw RynBridgeError(code: .unknown, message: "Keychain update failed with status: \(updateStatus)")
        }
    }

    public func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw RynBridgeError(code: .unknown, message: "Keychain delete failed with status: \(status)")
        }
    }

    public func has(key: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            return true
        } else if status == errSecItemNotFound {
            return false
        } else {
            throw RynBridgeError(code: .unknown, message: "Keychain query failed with status: \(status)")
        }
    }
}
