import Foundation

public enum ErrorCode: String, Sendable {
    case timeout = "TIMEOUT"
    case moduleNotFound = "MODULE_NOT_FOUND"
    case actionNotFound = "ACTION_NOT_FOUND"
    case invalidMessage = "INVALID_MESSAGE"
    case serializationError = "SERIALIZATION_ERROR"
    case transportError = "TRANSPORT_ERROR"
    case versionMismatch = "VERSION_MISMATCH"
    case unknown = "UNKNOWN"
}

public struct RynBridgeError: Error, Sendable, Equatable {
    public let code: ErrorCode
    public let message: String
    public let details: [String: AnyCodable]?

    public init(code: ErrorCode, message: String, details: [String: AnyCodable]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }

    public var errorData: BridgeErrorData {
        BridgeErrorData(code: code.rawValue, message: message, details: details)
    }
}
