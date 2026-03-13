import Foundation
import RynBridge

public struct BluetoothModule: BridgeModule, Sendable {
    public let name = "bluetooth"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init() {
        self.init(provider: DefaultBluetoothProvider())
    }

    public init(provider: BluetoothProvider) {
        actions = [
            "startScan": { payload in
                let serviceUUIDs: [String]?
                if let arr = payload["serviceUUIDs"]?.arrayValue {
                    serviceUUIDs = arr.compactMap { $0.stringValue }
                } else {
                    serviceUUIDs = nil
                }
                let success = try await provider.startScan(serviceUUIDs: serviceUUIDs)
                return ["success": .bool(success)]
            },
            "stopScan": { _ in
                provider.stopScan()
                return [:]
            },
            "connect": { payload in
                guard let deviceId = payload["deviceId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: deviceId")
                }
                let success = try await provider.connect(deviceId: deviceId)
                return ["success": .bool(success)]
            },
            "disconnect": { payload in
                guard let deviceId = payload["deviceId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: deviceId")
                }
                let success = try await provider.disconnect(deviceId: deviceId)
                return ["success": .bool(success)]
            },
            "getServices": { payload in
                guard let deviceId = payload["deviceId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: deviceId")
                }
                let services = try await provider.getServices(deviceId: deviceId)
                return ["services": .array(services.map { .dictionary($0) })]
            },
            "readCharacteristic": { payload in
                guard let deviceId = payload["deviceId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: deviceId")
                }
                guard let serviceUUID = payload["serviceUUID"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: serviceUUID")
                }
                guard let characteristicUUID = payload["characteristicUUID"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: characteristicUUID")
                }
                let value = try await provider.readCharacteristic(
                    deviceId: deviceId,
                    serviceUUID: serviceUUID,
                    characteristicUUID: characteristicUUID
                )
                return ["value": .string(value)]
            },
            "writeCharacteristic": { payload in
                guard let deviceId = payload["deviceId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: deviceId")
                }
                guard let serviceUUID = payload["serviceUUID"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: serviceUUID")
                }
                guard let characteristicUUID = payload["characteristicUUID"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: characteristicUUID")
                }
                guard let value = payload["value"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: value")
                }
                let success = try await provider.writeCharacteristic(
                    deviceId: deviceId,
                    serviceUUID: serviceUUID,
                    characteristicUUID: characteristicUUID,
                    value: value
                )
                return ["success": .bool(success)]
            },
            "requestPermission": { _ in
                let granted = try await provider.requestPermission()
                return ["granted": .bool(granted)]
            },
            "getState": { _ in
                let state = try await provider.getState()
                return ["state": .string(state)]
            },
        ]
    }
}
