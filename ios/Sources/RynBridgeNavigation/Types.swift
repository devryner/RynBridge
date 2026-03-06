import Foundation
import RynBridge

public struct PushPayload: Sendable {
    public let screen: String
    public let params: [String: AnyCodable]?

    public init(screen: String, params: [String: AnyCodable]? = nil) {
        self.screen = screen
        self.params = params
    }
}

public struct PopResult: Sendable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "success": .bool(success),
        ]
    }
}

public struct PresentPayload: Sendable {
    public let screen: String
    public let style: String?
    public let params: [String: AnyCodable]?

    public init(screen: String, style: String? = nil, params: [String: AnyCodable]? = nil) {
        self.screen = screen
        self.style = style
        self.params = params
    }
}

public struct OpenURLResult: Sendable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "success": .bool(success),
        ]
    }
}

public struct CanOpenURLResult: Sendable {
    public let canOpen: Bool

    public init(canOpen: Bool) {
        self.canOpen = canOpen
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "canOpen": .bool(canOpen),
        ]
    }
}

public struct InitialURLResult: Sendable {
    public let url: String?

    public init(url: String?) {
        self.url = url
    }

    public func toPayload() -> [String: AnyCodable] {
        if let url = url {
            return ["url": .string(url)]
        } else {
            return ["url": .null]
        }
    }
}

public struct AppStateResult: Sendable {
    public let state: String

    public init(state: String) {
        self.state = state
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "state": .string(state),
        ]
    }
}

public protocol NavigationProvider: Sendable {
    func push(screen: String, params: [String: AnyCodable]?) async throws -> PopResult
    func pop() async throws -> PopResult
    func popToRoot() async throws -> PopResult
    func present(screen: String, style: String?, params: [String: AnyCodable]?) async throws -> PopResult
    func dismiss() async throws -> PopResult
    func openURL(url: String) async throws -> OpenURLResult
    func canOpenURL(url: String) async throws -> CanOpenURLResult
    func getInitialURL() async throws -> InitialURLResult
    func getAppState() async throws -> AppStateResult
}
