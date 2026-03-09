#if canImport(UIKit)
import Foundation
import UIKit
import RynBridge

public final class DefaultNavigationProvider: NavigationProvider, @unchecked Sendable {
    private var initialURL: String?
    private var screenFactory: (@MainActor @Sendable (String, [String: AnyCodable]?) -> UIViewController?)?

    public init(initialURL: String? = nil) {
        self.initialURL = initialURL
    }

    /// Register a factory to create UIViewControllers for screen names.
    /// Without this, push/present will create a basic UIViewController with the screen name as title.
    public func setScreenFactory(_ factory: @escaping @MainActor @Sendable (String, [String: AnyCodable]?) -> UIViewController?) {
        self.screenFactory = factory
    }

    @MainActor
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    @MainActor
    private func topNavigationController() -> UINavigationController? {
        guard let top = topViewController() else { return nil }
        if let nav = top as? UINavigationController { return nav }
        return top.navigationController
    }

    @MainActor
    private func createViewController(screen: String, params: [String: AnyCodable]?) -> UIViewController {
        if let factory = screenFactory, let vc = factory(screen, params) {
            return vc
        }
        let vc = UIViewController()
        vc.title = screen
        vc.view.backgroundColor = .systemBackground
        return vc
    }

    public func push(screen: String, params: [String: AnyCodable]?) async throws -> PopResult {
        return await MainActor.run {
            guard let nav = topNavigationController() else {
                return PopResult(success: false)
            }
            let vc = createViewController(screen: screen, params: params)
            nav.pushViewController(vc, animated: true)
            return PopResult(success: true)
        }
    }

    public func pop() async throws -> PopResult {
        return await MainActor.run {
            guard let nav = topNavigationController(), nav.viewControllers.count > 1 else {
                return PopResult(success: false)
            }
            nav.popViewController(animated: true)
            return PopResult(success: true)
        }
    }

    public func popToRoot() async throws -> PopResult {
        return await MainActor.run {
            guard let nav = topNavigationController() else {
                return PopResult(success: false)
            }
            nav.popToRootViewController(animated: true)
            return PopResult(success: true)
        }
    }

    public func present(screen: String, style: String?, params: [String: AnyCodable]?) async throws -> PopResult {
        return await MainActor.run {
            guard let top = topViewController() else {
                return PopResult(success: false)
            }
            let vc = createViewController(screen: screen, params: params)
            switch style {
            case "fullScreen":
                vc.modalPresentationStyle = .fullScreen
            case "pageSheet":
                vc.modalPresentationStyle = .pageSheet
            case "formSheet":
                vc.modalPresentationStyle = .formSheet
            case "overFullScreen":
                vc.modalPresentationStyle = .overFullScreen
            default:
                vc.modalPresentationStyle = .automatic
            }
            top.present(vc, animated: true)
            return PopResult(success: true)
        }
    }

    public func dismiss() async throws -> PopResult {
        return await MainActor.run {
            guard let top = topViewController(), top.presentingViewController != nil else {
                return PopResult(success: false)
            }
            top.dismiss(animated: true)
            return PopResult(success: true)
        }
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
