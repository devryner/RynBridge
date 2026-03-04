import Foundation
import RynBridge

public struct PushRegistration: Sendable {
    public let token: String
    public let platform: String

    public init(token: String, platform: String) {
        self.token = token
        self.platform = platform
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "token": .string(token),
            "platform": .string(platform),
        ]
    }
}

public struct PushPermissionStatus: Sendable {
    public let status: String

    public init(status: String) {
        self.status = status
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "status": .string(status),
        ]
    }
}

public protocol PushProvider: Sendable {
    func register() async throws -> PushRegistration
    func unregister() async throws
    func getToken() async throws -> String?
    func requestPermission() async throws -> Bool
    func getPermissionStatus() async throws -> PushPermissionStatus
}
