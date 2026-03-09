#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth
import RynBridge

public final class DefaultBluetoothProvider: NSObject, BluetoothProvider, CBCentralManagerDelegate, CBPeripheralDelegate, @unchecked Sendable {
    private let queue = DispatchQueue(label: "io.rynbridge.bluetooth")
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var connectedPeripherals: [String: CBPeripheral] = [:]
    private var stateReadyContinuation: CheckedContinuation<Void, Never>?
    private var connectContinuations: [String: CheckedContinuation<Bool, any Error>] = [:]
    private var disconnectContinuations: [String: CheckedContinuation<Bool, any Error>] = [:]
    private var serviceDiscoveryContinuations: [String: CheckedContinuation<[[String: AnyCodable]], any Error>] = [:]
    private var readContinuations: [String: CheckedContinuation<String, any Error>] = [:]
    private var writeContinuations: [String: CheckedContinuation<Bool, any Error>] = [:]

    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }

    private func waitForPoweredOn() async {
        if centralManager.state == .poweredOn { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.sync {
                if centralManager.state == .poweredOn {
                    continuation.resume()
                } else {
                    stateReadyContinuation = continuation
                }
            }
        }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            stateReadyContinuation?.resume()
            stateReadyContinuation = nil
        }
    }

    // MARK: - BluetoothProvider

    public func startScan(serviceUUIDs: [String]?) async throws -> Bool {
        await waitForPoweredOn()
        let cbuuids = serviceUUIDs?.map { CBUUID(string: $0) }
        centralManager.scanForPeripherals(withServices: cbuuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        return true
    }

    public func stopScan() {
        centralManager.stopScan()
    }

    public func connect(deviceId: String) async throws -> Bool {
        guard let peripheral = queue.sync(execute: { discoveredPeripherals[deviceId] }) else {
            throw RynBridgeError(code: .unknown, message: "Device not found: \(deviceId)")
        }
        return try await withCheckedThrowingContinuation { continuation in
            queue.sync {
                connectContinuations[deviceId] = continuation
            }
            centralManager.connect(peripheral, options: nil)
        }
    }

    public func disconnect(deviceId: String) async throws -> Bool {
        guard let peripheral = queue.sync(execute: { connectedPeripherals[deviceId] }) else {
            throw RynBridgeError(code: .unknown, message: "Device not connected: \(deviceId)")
        }
        return try await withCheckedThrowingContinuation { continuation in
            queue.sync {
                disconnectContinuations[deviceId] = continuation
            }
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    public func getServices(deviceId: String) async throws -> [[String: AnyCodable]] {
        guard let peripheral = queue.sync(execute: { connectedPeripherals[deviceId] }) else {
            throw RynBridgeError(code: .unknown, message: "Device not connected: \(deviceId)")
        }
        return try await withCheckedThrowingContinuation { continuation in
            queue.sync {
                serviceDiscoveryContinuations[deviceId] = continuation
            }
            peripheral.discoverServices(nil)
        }
    }

    public func readCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String) async throws -> String {
        guard let peripheral = queue.sync(execute: { connectedPeripherals[deviceId] }) else {
            throw RynBridgeError(code: .unknown, message: "Device not connected: \(deviceId)")
        }
        let targetService = peripheral.services?.first { $0.uuid == CBUUID(string: serviceUUID) }
        guard let service = targetService else {
            throw RynBridgeError(code: .unknown, message: "Service not found: \(serviceUUID)")
        }
        let targetChar = service.characteristics?.first { $0.uuid == CBUUID(string: characteristicUUID) }
        guard let characteristic = targetChar else {
            throw RynBridgeError(code: .unknown, message: "Characteristic not found: \(characteristicUUID)")
        }
        let key = "\(deviceId):\(characteristicUUID)"
        return try await withCheckedThrowingContinuation { continuation in
            queue.sync {
                readContinuations[key] = continuation
            }
            peripheral.readValue(for: characteristic)
        }
    }

    public func writeCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String, value: String) async throws -> Bool {
        guard let peripheral = queue.sync(execute: { connectedPeripherals[deviceId] }) else {
            throw RynBridgeError(code: .unknown, message: "Device not connected: \(deviceId)")
        }
        let targetService = peripheral.services?.first { $0.uuid == CBUUID(string: serviceUUID) }
        guard let service = targetService else {
            throw RynBridgeError(code: .unknown, message: "Service not found: \(serviceUUID)")
        }
        let targetChar = service.characteristics?.first { $0.uuid == CBUUID(string: characteristicUUID) }
        guard let characteristic = targetChar else {
            throw RynBridgeError(code: .unknown, message: "Characteristic not found: \(characteristicUUID)")
        }
        guard let data = Data(base64Encoded: value) else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid base64 value")
        }
        let key = "\(deviceId):\(characteristicUUID)"
        return try await withCheckedThrowingContinuation { continuation in
            queue.sync {
                writeContinuations[key] = continuation
            }
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    public func requestPermission() async throws -> Bool {
        switch CBCentralManager.authorization {
        case .allowedAlways:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            await waitForPoweredOn()
            return CBCentralManager.authorization == .allowedAlways
        @unknown default:
            return false
        }
    }

    public func getState() async throws -> String {
        switch centralManager.state {
        case .poweredOn: return "poweredOn"
        case .poweredOff: return "poweredOff"
        case .resetting: return "resetting"
        case .unauthorized: return "unauthorized"
        case .unsupported: return "unsupported"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let id = peripheral.identifier.uuidString
        discoveredPeripherals[id] = peripheral
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let id = peripheral.identifier.uuidString
        connectedPeripherals[id] = peripheral
        peripheral.delegate = self
        connectContinuations.removeValue(forKey: id)?.resume(returning: true)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        let id = peripheral.identifier.uuidString
        let err = RynBridgeError(code: .unknown, message: error?.localizedDescription ?? "Failed to connect")
        connectContinuations.removeValue(forKey: id)?.resume(throwing: err)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        let id = peripheral.identifier.uuidString
        connectedPeripherals.removeValue(forKey: id)
        disconnectContinuations.removeValue(forKey: id)?.resume(returning: true)
    }

    // MARK: - CBPeripheralDelegate

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        let id = peripheral.identifier.uuidString
        if let error {
            serviceDiscoveryContinuations.removeValue(forKey: id)?.resume(throwing: RynBridgeError(code: .unknown, message: error.localizedDescription))
            return
        }
        guard let services = peripheral.services else {
            serviceDiscoveryContinuations.removeValue(forKey: id)?.resume(returning: [])
            return
        }
        // Discover characteristics for each service
        var remaining = services.count
        if remaining == 0 {
            serviceDiscoveryContinuations.removeValue(forKey: id)?.resume(returning: [])
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        let id = peripheral.identifier.uuidString
        guard let services = peripheral.services else { return }
        // Check if all services have their characteristics discovered
        let allDiscovered = services.allSatisfy { $0.characteristics != nil }
        guard allDiscovered else { return }

        let result: [[String: AnyCodable]] = services.map { svc in
            let chars: [AnyCodable] = (svc.characteristics ?? []).map { char in
                .dictionary([
                    "uuid": .string(char.uuid.uuidString),
                    "properties": .array(Self.characteristicProperties(char.properties)),
                ])
            }
            return [
                "uuid": .string(svc.uuid.uuidString),
                "characteristics": .array(chars),
            ]
        }
        serviceDiscoveryContinuations.removeValue(forKey: id)?.resume(returning: result)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        let id = peripheral.identifier.uuidString
        let key = "\(id):\(characteristic.uuid.uuidString)"
        if let error {
            readContinuations.removeValue(forKey: key)?.resume(throwing: RynBridgeError(code: .unknown, message: error.localizedDescription))
            return
        }
        let base64 = characteristic.value?.base64EncodedString() ?? ""
        readContinuations.removeValue(forKey: key)?.resume(returning: base64)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        let id = peripheral.identifier.uuidString
        let key = "\(id):\(characteristic.uuid.uuidString)"
        if let error {
            writeContinuations.removeValue(forKey: key)?.resume(throwing: RynBridgeError(code: .unknown, message: error.localizedDescription))
            return
        }
        writeContinuations.removeValue(forKey: key)?.resume(returning: true)
    }

    private static func characteristicProperties(_ props: CBCharacteristicProperties) -> [AnyCodable] {
        var result: [AnyCodable] = []
        if props.contains(.read) { result.append(.string("read")) }
        if props.contains(.write) { result.append(.string("write")) }
        if props.contains(.writeWithoutResponse) { result.append(.string("writeWithoutResponse")) }
        if props.contains(.notify) { result.append(.string("notify")) }
        if props.contains(.indicate) { result.append(.string("indicate")) }
        return result
    }
}
#endif
