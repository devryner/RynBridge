import Foundation
import RynBridge

public protocol BackgroundTaskProvider: Sendable {
    func scheduleTask(taskId: String, type: String, interval: Int?, delay: Int?, requiresNetwork: Bool, requiresCharging: Bool) async throws -> Bool
    func cancelTask(taskId: String) async throws -> Bool
    func cancelAllTasks() async throws -> Bool
    func getScheduledTasks() async throws -> [[String: AnyCodable]]
    func completeTask(taskId: String, success: Bool)
    func requestPermission() async throws -> Bool
}
