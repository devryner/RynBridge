import Foundation
import RynBridge

public struct PushModule: BridgeModule, Sendable {
    public let name = "push"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: PushProvider) {
        actions = [
            "register": { _ in
                let result = try await provider.register()
                return result.toPayload()
            },
            "unregister": { _ in
                try await provider.unregister()
                return [:]
            },
            "getToken": { _ in
                let token = try await provider.getToken()
                return ["token": token.map { .string($0) } ?? .null]
            },
            "requestPermission": { _ in
                let granted = try await provider.requestPermission()
                return ["granted": .bool(granted)]
            },
            "getPermissionStatus": { _ in
                let result = try await provider.getPermissionStatus()
                return result.toPayload()
            },
            "getInitialNotification": { _ in
                let notification = try await provider.getInitialNotification()
                return notification?.toPayload() ?? [
                    "title": .null,
                    "body": .null,
                    "data": .null,
                ]
            },
        ]
    }
}
