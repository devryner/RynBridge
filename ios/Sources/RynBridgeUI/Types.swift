import Foundation
import RynBridge

public struct ShowAlertPayload: Sendable {
    public let title: String
    public let message: String
    public let buttonText: String

    public init(title: String, message: String, buttonText: String = "OK") {
        self.title = title
        self.message = message
        self.buttonText = buttonText
    }
}

public struct ShowConfirmPayload: Sendable {
    public let title: String
    public let message: String
    public let confirmText: String
    public let cancelText: String

    public init(title: String, message: String, confirmText: String = "Confirm", cancelText: String = "Cancel") {
        self.title = title
        self.message = message
        self.confirmText = confirmText
        self.cancelText = cancelText
    }
}

public struct ShowToastPayload: Sendable {
    public let message: String
    public let duration: Double

    public init(message: String, duration: Double = 2.0) {
        self.message = message
        self.duration = duration
    }
}

public struct ShowActionSheetPayload: Sendable {
    public let title: String?
    public let options: [String]

    public init(title: String? = nil, options: [String]) {
        self.title = title
        self.options = options
    }
}

public struct SetStatusBarPayload: Sendable {
    public let style: String?
    public let hidden: Bool?

    public init(style: String? = nil, hidden: Bool? = nil) {
        self.style = style
        self.hidden = hidden
    }
}

public protocol UIProvider: Sendable {
    func showAlert(title: String, message: String, buttonText: String) async
    func showConfirm(title: String, message: String, confirmText: String, cancelText: String) async -> Bool
    func showToast(message: String, duration: Double)
    func showActionSheet(title: String?, options: [String]) async -> Int
    func setStatusBar(style: String?, hidden: Bool?) async
}
