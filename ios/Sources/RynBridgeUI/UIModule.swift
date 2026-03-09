import Foundation
import RynBridge

public struct UIModule: BridgeModule, Sendable {
    public let name = "ui"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: UIProvider) {
        actions = [
            "showAlert": { payload in
                let title = payload["title"]?.stringValue ?? ""
                let message = payload["message"]?.stringValue ?? ""
                let buttonText = payload["buttonText"]?.stringValue ?? "OK"
                await provider.showAlert(title: title, message: message, buttonText: buttonText)
                return [:]
            },
            "showConfirm": { payload in
                let title = payload["title"]?.stringValue ?? ""
                let message = payload["message"]?.stringValue ?? ""
                let confirmText = payload["confirmText"]?.stringValue ?? "Confirm"
                let cancelText = payload["cancelText"]?.stringValue ?? "Cancel"
                let confirmed = await provider.showConfirm(
                    title: title, message: message,
                    confirmText: confirmText, cancelText: cancelText
                )
                return ["confirmed": .bool(confirmed)]
            },
            "showToast": { payload in
                let message = payload["message"]?.stringValue ?? ""
                let duration = payload["duration"]?.doubleValue ?? 2.0
                provider.showToast(message: message, duration: duration)
                return [:]
            },
            "showActionSheet": { payload in
                let title = payload["title"]?.stringValue
                let options: [String]
                if let arr = payload["options"]?.arrayValue {
                    options = arr.compactMap { $0.stringValue }
                } else {
                    options = []
                }
                let selectedIndex = await provider.showActionSheet(title: title, options: options)
                return ["selectedIndex": .int(selectedIndex)]
            },
            "setStatusBar": { payload in
                let style = payload["style"]?.stringValue
                let hidden = payload["hidden"]?.boolValue
                await provider.setStatusBar(style: style, hidden: hidden)
                return [:]
            },
            "showKeyboard": { _ in
                await provider.showKeyboard()
                return [:]
            },
            "hideKeyboard": { _ in
                await provider.hideKeyboard()
                return [:]
            },
            "getKeyboardHeight": { _ in
                let info = await provider.getKeyboardHeight()
                return info.toPayload()
            },
        ]
    }
}

#if canImport(UIKit)
import UIKit

@MainActor
public final class DefaultUIProvider: UIProvider {
    private var keyboardHeight: Double = 0
    private var keyboardVisible: Bool = false

    public init() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self?.keyboardHeight = frame.height
                self?.keyboardVisible = true
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.keyboardHeight = 0
            self?.keyboardVisible = false
        }
    }

    nonisolated public func showAlert(title: String, message: String, buttonText: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                guard let viewController = Self.topViewController() else {
                    continuation.resume()
                    return
                }
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: buttonText, style: .default) { _ in
                    continuation.resume()
                })
                viewController.present(alert, animated: true)
            }
        }
    }

    nonisolated public func showConfirm(title: String, message: String, confirmText: String, cancelText: String) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            Task { @MainActor in
                guard let viewController = Self.topViewController() else {
                    continuation.resume(returning: false)
                    return
                }
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: cancelText, style: .cancel) { _ in
                    continuation.resume(returning: false)
                })
                alert.addAction(UIAlertAction(title: confirmText, style: .default) { _ in
                    continuation.resume(returning: true)
                })
                viewController.present(alert, animated: true)
            }
        }
    }

    nonisolated public func showToast(message: String, duration: Double) {
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

            let label = UILabel()
            label.text = message
            label.textAlignment = .center
            label.textColor = .white
            label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
            label.numberOfLines = 0

            let padding: CGFloat = 16
            let maxWidth = window.bounds.width - 2 * padding
            let size = label.sizeThatFits(CGSize(width: maxWidth - 2 * padding, height: .greatestFiniteMagnitude))
            label.frame = CGRect(
                x: (window.bounds.width - size.width - 2 * padding) / 2,
                y: window.bounds.height - window.safeAreaInsets.bottom - size.height - 2 * padding - 20,
                width: size.width + 2 * padding,
                height: size.height + 2 * padding
            )
            label.alpha = 0
            window.addSubview(label)

            UIView.animate(withDuration: 0.3) {
                label.alpha = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    label.alpha = 0
                }, completion: { _ in
                    label.removeFromSuperview()
                })
            }
        }
    }

    nonisolated public func showActionSheet(title: String?, options: [String]) async -> Int {
        await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
            Task { @MainActor in
                guard let viewController = Self.topViewController() else {
                    continuation.resume(returning: -1)
                    return
                }
                let sheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
                for (index, option) in options.enumerated() {
                    sheet.addAction(UIAlertAction(title: option, style: .default) { _ in
                        continuation.resume(returning: index)
                    })
                }
                sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    continuation.resume(returning: -1)
                })
                viewController.present(sheet, animated: true)
            }
        }
    }

    nonisolated public func setStatusBar(style: String?, hidden: Bool?) async {
        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first else { return }

            if let hidden {
                let geometry = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: windowScene.interfaceOrientation.isLandscape ? .landscape : .portrait)
                if hidden {
                    windowScene.requestGeometryUpdate(geometry)
                }
            }
            if let style {
                let barStyle: UIStatusBarStyle
                switch style {
                case "light":
                    barStyle = .lightContent
                case "dark":
                    barStyle = .darkContent
                default:
                    barStyle = .default
                }
                // Post notification for host app to handle status bar style change
                NotificationCenter.default.post(
                    name: Notification.Name("RynBridgeStatusBarStyleChange"),
                    object: nil,
                    userInfo: ["style": barStyle, "hidden": hidden ?? false]
                )
            }
        }
    }

    nonisolated public func showKeyboard() async {
        await MainActor.run {
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    nonisolated public func hideKeyboard() async {
        await MainActor.run {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    nonisolated public func getKeyboardHeight() async -> KeyboardInfo {
        return await MainActor.run {
            return KeyboardInfo(height: keyboardHeight, visible: keyboardVisible)
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
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
}
#endif
