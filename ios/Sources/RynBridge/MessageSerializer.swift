import Foundation

public struct MessageSerializer: Sendable {
    private let version: String
    private let encoder: JSONEncoder

    public init(version: String = "0.1.0") {
        self.version = version
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.sortedKeys]
    }

    public func createRequest(module: String, action: String, payload: [String: AnyCodable] = [:]) -> BridgeRequest {
        BridgeRequest(
            id: UUID().uuidString.lowercased(),
            module: module,
            action: action,
            payload: payload,
            version: version
        )
    }

    public func createResponse(id: String, status: ResponseStatus, payload: [String: AnyCodable] = [:], error: BridgeErrorData? = nil) -> BridgeResponse {
        BridgeResponse(id: id, status: status, payload: payload, error: error)
    }

    public func serialize(_ request: BridgeRequest) throws -> String {
        do {
            let data = try encoder.encode(request)
            guard let json = String(data: data, encoding: .utf8) else {
                throw RynBridgeError(code: .serializationError, message: "Failed to encode request to UTF-8 string")
            }
            return json
        } catch let error as RynBridgeError {
            throw error
        } catch {
            throw RynBridgeError(code: .serializationError, message: "Failed to serialize request: \(error.localizedDescription)")
        }
    }

    public func serialize(_ response: BridgeResponse) throws -> String {
        do {
            let data = try encoder.encode(response)
            guard let json = String(data: data, encoding: .utf8) else {
                throw RynBridgeError(code: .serializationError, message: "Failed to encode response to UTF-8 string")
            }
            return json
        } catch let error as RynBridgeError {
            throw error
        } catch {
            throw RynBridgeError(code: .serializationError, message: "Failed to serialize response: \(error.localizedDescription)")
        }
    }
}
