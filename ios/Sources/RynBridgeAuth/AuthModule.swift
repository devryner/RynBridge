import Foundation
import RynBridge

public struct AuthModule: BridgeModule, Sendable {
    public let name = "auth"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: AuthProvider) {
        actions = [
            "login": { payload in
                guard let providerName = payload["provider"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: provider")
                }
                let scopes: [String]
                if let arr = payload["scopes"]?.arrayValue {
                    scopes = arr.compactMap { $0.stringValue }
                } else {
                    scopes = []
                }
                let result = try await provider.login(provider: providerName, scopes: scopes)
                return result.toPayload()
            },
            "logout": { _ in
                try await provider.logout()
                return [:]
            },
            "getToken": { _ in
                let result = try await provider.getToken()
                return result.toPayload()
            },
            "refreshToken": { _ in
                let result = try await provider.refreshToken()
                return result.toPayload()
            },
            "getUser": { _ in
                let user = try await provider.getUser()
                return ["user": user.map { .dictionary($0.toPayload()) } ?? .null]
            },
        ]
    }
}
