import Foundation

public struct MessageDeserializer: Sendable {
    private let decoder: JSONDecoder

    public init() {
        self.decoder = JSONDecoder()
    }

    public func deserialize(_ raw: String) throws -> IncomingMessage {
        guard let data = raw.data(using: .utf8) else {
            throw RynBridgeError(code: .invalidMessage, message: "Failed to convert message to UTF-8 data")
        }

        let json: [String: AnyCodable]
        do {
            json = try decoder.decode([String: AnyCodable].self, from: data)
        } catch {
            throw RynBridgeError(code: .invalidMessage, message: "Failed to parse JSON: \(error.localizedDescription)")
        }

        guard let id = json["id"]?.stringValue, !id.isEmpty else {
            throw RynBridgeError(code: .invalidMessage, message: "Message missing required field: id")
        }

        // Discriminate by "status" field: present → response, absent → request
        if json["status"] != nil {
            let response = try decodeResponse(from: data)
            return .response(response)
        } else {
            let request = try decodeRequest(from: data)
            return .request(request)
        }
    }

    private func decodeRequest(from data: Data) throws -> BridgeRequest {
        do {
            let request = try decoder.decode(BridgeRequest.self, from: data)
            guard !request.module.isEmpty else {
                throw RynBridgeError(code: .invalidMessage, message: "Request missing required field: module")
            }
            guard !request.action.isEmpty else {
                throw RynBridgeError(code: .invalidMessage, message: "Request missing required field: action")
            }
            return request
        } catch let error as RynBridgeError {
            throw error
        } catch {
            throw RynBridgeError(code: .invalidMessage, message: "Failed to decode request: \(error.localizedDescription)")
        }
    }

    private func decodeResponse(from data: Data) throws -> BridgeResponse {
        do {
            return try decoder.decode(BridgeResponse.self, from: data)
        } catch {
            throw RynBridgeError(code: .invalidMessage, message: "Failed to decode response: \(error.localizedDescription)")
        }
    }
}
