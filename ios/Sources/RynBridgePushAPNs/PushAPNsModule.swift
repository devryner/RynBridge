import Foundation
import RynBridge

public struct PushAPNsModule: BridgeModule, Sendable {
    public let name = "push-apns"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: APNsPushProvider) {
        actions = [
            "getToken": { _ in
                let token = try await provider.getToken()
                return ["token": token.map { .string($0) } ?? .null]
            },
            "setBadgeCount": { payload in
                guard case let .int(count) = payload["count"] else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: count")
                }
                try await provider.setBadgeCount(Int(count))
                return [:]
            },
            "getBadgeCount": { _ in
                let count = try await provider.getBadgeCount()
                return APNsBadge(count: count).toPayload()
            },
            "removeAllDeliveredNotifications": { _ in
                try await provider.removeAllDeliveredNotifications()
                return [:]
            },
            "getDeliveredNotificationCount": { _ in
                let count = try await provider.getDeliveredNotificationCount()
                return ["count": .int(count)]
            },
        ]
    }
}
