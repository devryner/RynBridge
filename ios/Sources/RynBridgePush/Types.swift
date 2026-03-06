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

public struct PushNotificationData: Sendable {
    public let title: String?
    public let body: String?
    public let data: [String: AnyCodable]?

    public init(title: String? = nil, body: String? = nil, data: [String: AnyCodable]? = nil) {
        self.title = title
        self.body = body
        self.data = data
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "title": title.map { .string($0) } ?? .null,
            "body": body.map { .string($0) } ?? .null,
            "data": data.map { .dictionary($0) } ?? .null,
        ]
    }
}

public protocol PushProvider: Sendable {
    func register() async throws -> PushRegistration
    func unregister() async throws
    func getToken() async throws -> String?
    func requestPermission() async throws -> Bool
    func getPermissionStatus() async throws -> PushPermissionStatus
    func getInitialNotification() async throws -> PushNotificationData?
}
