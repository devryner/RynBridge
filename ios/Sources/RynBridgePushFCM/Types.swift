import Foundation
import RynBridge

public struct FCMToken: Sendable {
    public let token: String

    public init(token: String) {
        self.token = token
    }

    public func toPayload() -> [String: AnyCodable] {
        ["token": .string(token)]
    }
}

public struct FCMAutoInit: Sendable {
    public let enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }

    public func toPayload() -> [String: AnyCodable] {
        ["enabled": .bool(enabled)]
    }
}

public protocol FCMPushProvider: Sendable {
    func getToken() async throws -> String
    func deleteToken() async throws
    func subscribeToTopic(_ topic: String) async throws
    func unsubscribeFromTopic(_ topic: String) async throws
    func getAutoInitEnabled() async throws -> Bool
    func setAutoInitEnabled(_ enabled: Bool) async throws
}
