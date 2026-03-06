import Foundation
import RynBridge

#if canImport(UIKit)
import UIKit

public final class DefaultNavigationProvider: NavigationProvider, @unchecked Sendable {
    private var initialURL: String?

    public init(initialURL: String? = nil) {
        self.initialURL = initialURL
    }

    public func push(screen: String, params: [String: AnyCodable]?) async throws -> PopResult {
        throw RynBridgeError(code: .unknown, message: "push requires UINavigationController context. Use a custom provider.")
    }

    public func pop() async throws -> PopResult {
        throw RynBridgeError(code: .unknown, message: "pop requires UINavigationController context. Use a custom provider.")
    }

    public func popToRoot() async throws -> PopResult {
        throw RynBridgeError(code: .unknown, message: "popToRoot requires UINavigationController context. Use a custom provider.")
    }

    public func present(screen: String, style: String?, params: [String: AnyCodable]?) async throws -> PopResult {
        throw RynBridgeError(code: .unknown, message: "present requires UIViewController context. Use a custom provider.")
    }

    public func dismiss() async throws -> PopResult {
        throw RynBridgeError(code: .unknown, message: "dismiss requires UIViewController context. Use a custom provider.")
    }

    @MainActor
    public func openURL(url: String) async throws -> OpenURLResult {
        guard let parsed = URL(string: url) else {
            return OpenURLResult(success: false)
        }
        let success = await UIApplication.shared.open(parsed)
        return OpenURLResult(success: success)
    }

    @MainActor
    public func canOpenURL(url: String) async throws -> CanOpenURLResult {
        guard let parsed = URL(string: url) else {
            return CanOpenURLResult(canOpen: false)
        }
        let canOpen = UIApplication.shared.canOpenURL(parsed)
        return CanOpenURLResult(canOpen: canOpen)
    }

    public func getInitialURL() async throws -> InitialURLResult {
        return InitialURLResult(url: initialURL)
    }

    @MainActor
    public func getAppState() async throws -> AppStateResult {
        let state: String
        switch UIApplication.shared.applicationState {
        case .active:
            state = "active"
        case .inactive:
            state = "inactive"
        case .background:
            state = "background"
        @unknown default:
            state = "active"
        }
        return AppStateResult(state: state)
    }
}
#endif
