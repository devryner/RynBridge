import Foundation
import RynBridge

public protocol StorageProvider: Sendable {
    func get(key: String) -> String?
    func set(key: String, value: String)
    func remove(key: String)
    func clear()
    func keys() -> [String]
}
