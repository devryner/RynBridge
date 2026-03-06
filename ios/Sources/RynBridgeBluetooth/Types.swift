import Foundation
import RynBridge

public protocol BluetoothProvider: Sendable {
    func startScan(serviceUUIDs: [String]?) async throws -> Bool
    func stopScan()
    func connect(deviceId: String) async throws -> Bool
    func disconnect(deviceId: String) async throws -> Bool
    func getServices(deviceId: String) async throws -> [[String: AnyCodable]]
    func readCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String) async throws -> String
    func writeCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String, value: String) async throws -> Bool
    func requestPermission() async throws -> Bool
    func getState() async throws -> String
}
