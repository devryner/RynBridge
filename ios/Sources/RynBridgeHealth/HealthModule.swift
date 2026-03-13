import Foundation
import RynBridge

public struct HealthModule: BridgeModule, Sendable {
    public let name = "health"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init() {
        self.init(provider: DefaultHealthProvider())
    }

    public init(provider: HealthProvider) {
        actions = [
            "requestPermission": { payload in
                guard let readArr = payload["readTypes"]?.arrayValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: readTypes")
                }
                let readTypes = readArr.compactMap { $0.stringValue }
                let writeTypes: [String]
                if let writeArr = payload["writeTypes"]?.arrayValue {
                    writeTypes = writeArr.compactMap { $0.stringValue }
                } else {
                    writeTypes = []
                }
                let granted = try await provider.requestPermission(readTypes: readTypes, writeTypes: writeTypes)
                return ["granted": .bool(granted)]
            },
            "getPermissionStatus": { _ in
                let status = try await provider.getPermissionStatus()
                return ["status": .string(status)]
            },
            "queryData": { payload in
                guard let dataType = payload["dataType"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: dataType")
                }
                guard let startDate = payload["startDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: startDate")
                }
                guard let endDate = payload["endDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: endDate")
                }
                let limit = payload["limit"]?.intValue
                let records = try await provider.queryData(
                    dataType: dataType,
                    startDate: startDate,
                    endDate: endDate,
                    limit: limit
                )
                return ["records": .array(records.map { .dictionary($0) })]
            },
            "writeData": { payload in
                guard let dataType = payload["dataType"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: dataType")
                }
                guard let value = payload["value"]?.doubleValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: value")
                }
                guard let unit = payload["unit"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: unit")
                }
                guard let startDate = payload["startDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: startDate")
                }
                guard let endDate = payload["endDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: endDate")
                }
                let success = try await provider.writeData(
                    dataType: dataType,
                    value: value,
                    unit: unit,
                    startDate: startDate,
                    endDate: endDate
                )
                return ["success": .bool(success)]
            },
            "getSteps": { payload in
                guard let startDate = payload["startDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: startDate")
                }
                guard let endDate = payload["endDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: endDate")
                }
                let steps = try await provider.getSteps(startDate: startDate, endDate: endDate)
                return ["steps": .double(steps)]
            },
            "isAvailable": { _ in
                let available = try await provider.isAvailable()
                return ["available": .bool(available)]
            },
        ]
    }
}
