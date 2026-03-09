#if canImport(UIKit)
import Foundation
import UIKit
import RynBridge

public final class DefaultShareProvider: ShareProvider, @unchecked Sendable {

    public init() {}

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

    public func share(text: String?, url: String?, title: String?) async throws -> Bool {
        return await MainActor.run {
            guard let viewController = topViewController() else {
                return false
            }
            var items: [Any] = []
            if let text { items.append(text) }
            if let url, let parsedURL = URL(string: url) { items.append(parsedURL) }

            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let title {
                activityVC.setValue(title, forKey: "subject")
            }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            viewController.present(activityVC, animated: true)
            return true
        }
    }

    public func shareFile(filePath: String, mimeType: String) async throws -> Bool {
        return await MainActor.run {
            guard let viewController = topViewController() else {
                return false
            }
            let fileURL = URL(fileURLWithPath: filePath)
            guard FileManager.default.fileExists(atPath: filePath) else {
                return false
            }
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            viewController.present(activityVC, animated: true)
            return true
        }
    }

    public func copyToClipboard(text: String) async throws {
        UIPasteboard.general.string = text
    }

    public func readClipboard() async throws -> String? {
        return UIPasteboard.general.string
    }

    public func canShare() async throws -> Bool {
        return true
    }
}
#endif
