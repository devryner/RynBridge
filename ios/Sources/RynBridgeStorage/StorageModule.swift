import Foundation
import RynBridge

public struct StorageModule: BridgeModule, Sendable {
    public let name = "storage"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: StorageProvider) {
        actions = [
            "get": { payload in
                guard let key = payload["key"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: key")
                }
                let value = provider.get(key: key)
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
                provider.set(key: key, value: value)
                return [:]
            },
            "remove": { payload in
                guard let key = payload["key"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: key")
                }
                provider.remove(key: key)
                return [:]
            },
            "clear": { _ in
                provider.clear()
                return [:]
            },
            "keys": { _ in
                let allKeys = provider.keys()
                return ["keys": .array(allKeys.map { .string($0) })]
            },
        ]
    }
}

public final class UserDefaultsStorageProvider: StorageProvider, @unchecked Sendable {
    private let defaults: UserDefaults
    private let prefix: String

    public init(defaults: UserDefaults = .standard, prefix: String = "rynbridge.storage.") {
        self.defaults = defaults
        self.prefix = prefix
    }

    public func get(key: String) -> String? {
        defaults.string(forKey: prefix + key)
    }

    public func set(key: String, value: String) {
        defaults.set(value, forKey: prefix + key)
    }

    public func remove(key: String) {
        defaults.removeObject(forKey: prefix + key)
    }

    public func clear() {
        for key in keys() {
            defaults.removeObject(forKey: prefix + key)
        }
    }

    public func keys() -> [String] {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .sorted()
    }
}
