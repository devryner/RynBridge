import Foundation
import RynBridge

public struct AnalyticsModule: BridgeModule, Sendable {
    public let name = "analytics"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: AnalyticsProvider) {
        actions = [
            "logEvent": { payload in
                guard let eventName = payload["name"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: name")
                }
                let params: [String: AnyCodable]
                if let dict = payload["params"]?.dictionaryValue {
                    params = dict
                } else {
                    params = [:]
                }
                provider.logEvent(name: eventName, params: params)
                return [:]
            },
            "setUserProperty": { payload in
                guard let key = payload["key"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: key")
                }
                guard let value = payload["value"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: value")
                }
                provider.setUserProperty(key: key, value: value)
                return [:]
            },
            "setUserId": { payload in
                guard let userId = payload["userId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: userId")
                }
                provider.setUserId(userId)
                return [:]
            },
            "setScreen": { payload in
                guard let screenName = payload["name"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: name")
                }
                provider.setScreen(name: screenName)
                return [:]
            },
            "resetUser": { _ in
                provider.resetUser()
                return [:]
            },
            "setEnabled": { payload in
                guard let enabled = payload["enabled"]?.boolValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: enabled")
                }
                let result = try await provider.setEnabled(enabled)
                return ["enabled": .bool(result)]
            },
            "isEnabled": { _ in
                let result = try await provider.isEnabled()
                return ["enabled": .bool(result)]
            },
        ]
    }
}
