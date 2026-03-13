import Foundation
import RynBridge

public struct StorageModule: BridgeModule, Sendable {
    public let name = "storage"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init() {
        self.init(provider: DefaultStorageProvider())
    }

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
            "readFile": { payload in
                guard let path = payload["path"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: path")
                }
                let encoding = payload["encoding"]?.stringValue ?? "utf8"
                let content = try provider.readFile(path: path, encoding: encoding)
                return ["content": .string(content)]
            },
            "writeFile": { payload in
                guard let path = payload["path"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: path")
                }
                guard let content = payload["content"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: content")
                }
                let encoding = payload["encoding"]?.stringValue ?? "utf8"
                try provider.writeFile(path: path, content: content, encoding: encoding)
                return ["success": .bool(true)]
            },
            "deleteFile": { payload in
                guard let path = payload["path"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: path")
                }
                try provider.deleteFile(path: path)
                return ["success": .bool(true)]
            },
            "listDir": { payload in
                guard let path = payload["path"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: path")
                }
                let files = try provider.listDir(path: path)
                return ["files": .array(files.map { .string($0) })]
            },
            "getFileInfo": { payload in
                guard let path = payload["path"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: path")
                }
                let info = try provider.getFileInfo(path: path)
                return info.toPayload()
            },
        ]
    }
}

public final class DefaultStorageProvider: StorageProvider, @unchecked Sendable {
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

    public func readFile(path: String, encoding: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        if encoding == "base64" {
            return data.base64EncodedString()
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw RynBridgeError(code: .unknown, message: "Failed to decode file as UTF-8")
        }
        return text
    }

    public func writeFile(path: String, content: String, encoding: String) throws {
        let url = URL(fileURLWithPath: path)
        let data: Data
        if encoding == "base64" {
            guard let decoded = Data(base64Encoded: content) else {
                throw RynBridgeError(code: .invalidMessage, message: "Invalid base64 content")
            }
            data = decoded
        } else {
            guard let encoded = content.data(using: .utf8) else {
                throw RynBridgeError(code: .unknown, message: "Failed to encode content as UTF-8")
            }
            data = encoded
        }
        try data.write(to: url)
    }

    public func deleteFile(path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }

    public func listDir(path: String) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: path)
    }

    public func getFileInfo(path: String) throws -> FileInfo {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let size = (attrs[.size] as? Int) ?? 0
        let modDate = (attrs[.modificationDate] as? Date) ?? Date()
        let isDir = (attrs[.type] as? FileAttributeType) == .typeDirectory

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let modifiedAt = formatter.string(from: modDate)

        return FileInfo(size: size, modifiedAt: modifiedAt, isDirectory: isDir)
    }
}
