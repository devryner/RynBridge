#if os(iOS)
import Foundation
import BackgroundTasks
import RynBridge

public final class DefaultBackgroundTaskProvider: BackgroundTaskProvider, @unchecked Sendable {
    private let queue = DispatchQueue(label: "io.rynbridge.backgroundtask")
    private var scheduledTasks: [String: BGTaskRequest] = [:]

    public init() {}

    public func scheduleTask(taskId: String, type: String, interval: Int?, delay: Int?, requiresNetwork: Bool, requiresCharging: Bool) async throws -> Bool {
        let request: BGTaskRequest
        if type == "processing" {
            let processingRequest = BGProcessingTaskRequest(identifier: taskId)
            processingRequest.requiresNetworkConnectivity = requiresNetwork
            processingRequest.requiresExternalPower = requiresCharging
            if let delay {
                processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(delay / 1000))
            }
            request = processingRequest
        } else {
            let refreshRequest = BGAppRefreshTaskRequest(identifier: taskId)
            if let delay {
                refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(delay / 1000))
            }
            request = refreshRequest
        }

        try BGTaskScheduler.shared.submit(request)
        queue.sync { scheduledTasks[taskId] = request }
        return true
    }

    public func cancelTask(taskId: String) async throws -> Bool {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskId)
        _ = queue.sync { scheduledTasks.removeValue(forKey: taskId) }
        return true
    }

    public func cancelAllTasks() async throws -> Bool {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        queue.sync { scheduledTasks.removeAll() }
        return true
    }

    public func getScheduledTasks() async throws -> [[String: AnyCodable]] {
        let pending = await BGTaskScheduler.shared.pendingTaskRequests()
        return pending.map { request in
            var dict: [String: AnyCodable] = [
                "taskId": .string(request.identifier),
            ]
            if let date = request.earliestBeginDate {
                dict["earliestBeginDate"] = .string(ISO8601DateFormatter().string(from: date))
            }
            if request is BGProcessingTaskRequest {
                dict["type"] = .string("processing")
            } else {
                dict["type"] = .string("refresh")
            }
            return dict
        }
    }

    public func completeTask(taskId: String, success: Bool) {
        // Task completion is handled by the system via BGTask.setTaskCompleted
    }

    public func requestPermission() async throws -> Bool {
        // Background tasks don't require explicit permission;
        // they require registration in Info.plist BGTaskSchedulerPermittedIdentifiers
        return true
    }
}
#endif
