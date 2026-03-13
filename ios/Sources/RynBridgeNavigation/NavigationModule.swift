import Foundation
import RynBridge

public struct NavigationModule: BridgeModule, Sendable {
    public let name = "navigation"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: NavigationProvider) {
        actions = [
            "push": { payload in
                let screen = payload["screen"]?.stringValue ?? ""
                let params = payload["params"]?.dictionaryValue
                let result = try await provider.push(screen: screen, params: params)
                return result.toPayload()
            },
            "pop": { _ in
                let result = try await provider.pop()
                return result.toPayload()
            },
            "popToRoot": { _ in
                let result = try await provider.popToRoot()
                return result.toPayload()
            },
            "present": { payload in
                let screen = payload["screen"]?.stringValue ?? ""
                let style = payload["style"]?.stringValue
                let params = payload["params"]?.dictionaryValue
                let result = try await provider.present(screen: screen, style: style, params: params)
                return result.toPayload()
            },
            "dismiss": { _ in
                let result = try await provider.dismiss()
                return result.toPayload()
            },
            "openURL": { payload in
                guard let url = payload["url"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: url")
                }
                let result = try await provider.openURL(url: url)
                return result.toPayload()
            },
            "canOpenURL": { payload in
                guard let url = payload["url"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: url")
                }
                let result = try await provider.canOpenURL(url: url)
                return result.toPayload()
            },
            "getInitialURL": { _ in
                let result = try await provider.getInitialURL()
                return result.toPayload()
            },
            "getAppState": { _ in
                let result = try await provider.getAppState()
                return result.toPayload()
            },
        ]
    }
}

#if canImport(UIKit)
extension NavigationModule {
    public init() {
        self.init(provider: DefaultNavigationProvider())
    }
}
#endif
