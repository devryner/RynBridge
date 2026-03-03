import Foundation
import RynBridge

public protocol SecureStorageProvider: Sendable {
    func get(key: String) throws -> String?
    func set(key: String, value: String) throws
    func remove(key: String) throws
    func has(key: String) throws -> Bool
}
