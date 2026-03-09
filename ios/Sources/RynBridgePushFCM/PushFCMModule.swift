import Foundation
import RynBridge

public struct PushFCMModule: BridgeModule, Sendable {
    public let name = "push-fcm"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: FCMPushProvider) {
        actions = [
            "getToken": { _ in
                let token = try await provider.getToken()
                return FCMToken(token: token).toPayload()
            },
            "deleteToken": { _ in
                try await provider.deleteToken()
                return [:]
            },
            "subscribeToTopic": { payload in
                guard case let .string(topic) = payload["topic"] else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: topic")
                }
                try await provider.subscribeToTopic(topic)
                return [:]
            },
            "unsubscribeFromTopic": { payload in
                guard case let .string(topic) = payload["topic"] else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: topic")
                }
                try await provider.unsubscribeFromTopic(topic)
                return [:]
            },
            "getAutoInitEnabled": { _ in
                let enabled = try await provider.getAutoInitEnabled()
                return FCMAutoInit(enabled: enabled).toPayload()
            },
            "setAutoInitEnabled": { payload in
                guard case let .bool(enabled) = payload["enabled"] else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: enabled")
                }
                try await provider.setAutoInitEnabled(enabled)
                return [:]
            },
        ]
    }
}
