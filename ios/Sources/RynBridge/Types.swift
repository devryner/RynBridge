import Foundation

public struct BridgeRequest: Codable, Sendable {
    public let id: String
    public let module: String
    public let action: String
    public let payload: [String: AnyCodable]
    public let version: String

    public init(id: String, module: String, action: String, payload: [String: AnyCodable] = [:], version: String) {
        self.id = id
        self.module = module
        self.action = action
        self.payload = payload
        self.version = version
    }
}

public struct BridgeResponse: Codable, Sendable {
    public let id: String
    public let status: ResponseStatus
    public let payload: [String: AnyCodable]
    public let error: BridgeErrorData?

    public init(id: String, status: ResponseStatus, payload: [String: AnyCodable] = [:], error: BridgeErrorData? = nil) {
        self.id = id
        self.status = status
        self.payload = payload
        self.error = error
    }
}

public enum ResponseStatus: String, Codable, Sendable {
    case success
    case error
}

public struct BridgeErrorData: Codable, Sendable, Equatable {
    public let code: String
    public let message: String
    public let details: [String: AnyCodable]?

    public init(code: String, message: String, details: [String: AnyCodable]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

public struct BridgeConfig: Sendable {
    public let timeout: TimeInterval
    public let version: String

    public init(timeout: TimeInterval = 30.0, version: String = "0.1.0") {
        self.timeout = timeout
        self.version = version
    }

    public static let `default` = BridgeConfig()
}

public typealias ActionHandler = @Sendable ([String: AnyCodable]) async throws -> [String: AnyCodable]

/// Closure type for emitting events from Native to Web.
/// Parameters: (module, action, payload)
public typealias BridgeEventEmitter = @Sendable (String, String, [String: AnyCodable]) -> Void

public protocol BridgeModule: Sendable {
    var name: String { get }
    var version: String { get }
    var actions: [String: ActionHandler] { get }
}

public enum IncomingMessage: Sendable {
    case request(BridgeRequest)
    case response(BridgeResponse)
}
