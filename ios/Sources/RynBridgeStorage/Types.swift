import Foundation
import RynBridge

public struct FileInfo: Sendable {
    public let size: Int
    public let modifiedAt: String
    public let isDirectory: Bool

    public init(size: Int, modifiedAt: String, isDirectory: Bool) {
        self.size = size
        self.modifiedAt = modifiedAt
        self.isDirectory = isDirectory
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "size": .int(size),
            "modifiedAt": .string(modifiedAt),
            "isDirectory": .bool(isDirectory),
        ]
    }
}

public protocol StorageProvider: Sendable {
    func get(key: String) -> String?
    func set(key: String, value: String)
    func remove(key: String)
    func clear()
    func keys() -> [String]
    func readFile(path: String, encoding: String) throws -> String
    func writeFile(path: String, content: String, encoding: String) throws
    func deleteFile(path: String) throws
    func listDir(path: String) throws -> [String]
    func getFileInfo(path: String) throws -> FileInfo
}
