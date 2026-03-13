import Foundation
import RynBridge

public struct APNsToken: Sendable {
    public let token: String

    public init(token: String) {
        self.token = token
    }

    public func toPayload() -> [String: AnyCodable] {
        ["token": .string(token)]
    }
}

public struct APNsBadge: Sendable {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }

    public func toPayload() -> [String: AnyCodable] {
        ["count": .int(count)]
    }
}

public protocol APNsPushProvider: Sendable {
    func getToken() async throws -> String?
    func setBadgeCount(_ count: Int) async throws
    func getBadgeCount() async throws -> Int
    func removeAllDeliveredNotifications() async throws
    func getDeliveredNotificationCount() async throws -> Int
}
