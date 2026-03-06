import Foundation
import RynBridge

public protocol HealthProvider: Sendable {
    func requestPermission(readTypes: [String], writeTypes: [String]) async throws -> Bool
    func getPermissionStatus() async throws -> String
    func queryData(dataType: String, startDate: String, endDate: String, limit: Int?) async throws -> [[String: AnyCodable]]
    func writeData(dataType: String, value: Double, unit: String, startDate: String, endDate: String) async throws -> Bool
    func getSteps(startDate: String, endDate: String) async throws -> Double
    func isAvailable() async throws -> Bool
}
