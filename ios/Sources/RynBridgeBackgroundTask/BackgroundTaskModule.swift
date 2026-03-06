import Foundation
import RynBridge

public struct BackgroundTaskModule: BridgeModule, Sendable {
    public let name = "backgroundTask"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: BackgroundTaskProvider) {
        actions = [
            "scheduleTask": { payload in
                guard let taskId = payload["taskId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: taskId")
                }
                guard let type = payload["type"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: type")
                }
                let interval = payload["interval"]?.intValue
                let delay = payload["delay"]?.intValue
                let requiresNetwork = payload["requiresNetwork"]?.boolValue ?? false
                let requiresCharging = payload["requiresCharging"]?.boolValue ?? false
                let success = try await provider.scheduleTask(
                    taskId: taskId,
                    type: type,
                    interval: interval,
                    delay: delay,
                    requiresNetwork: requiresNetwork,
                    requiresCharging: requiresCharging
                )
                return ["taskId": .string(taskId), "success": .bool(success)]
            },
            "cancelTask": { payload in
                guard let taskId = payload["taskId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: taskId")
                }
                let success = try await provider.cancelTask(taskId: taskId)
                return ["success": .bool(success)]
            },
            "cancelAllTasks": { _ in
                let success = try await provider.cancelAllTasks()
                return ["success": .bool(success)]
            },
            "getScheduledTasks": { _ in
                let tasks = try await provider.getScheduledTasks()
                return ["tasks": .array(tasks.map { .dictionary($0) })]
            },
            "completeTask": { payload in
                guard let taskId = payload["taskId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: taskId")
                }
                let success = payload["success"]?.boolValue ?? true
                provider.completeTask(taskId: taskId, success: success)
                return [:]
            },
            "requestPermission": { _ in
                let granted = try await provider.requestPermission()
                return ["granted": .bool(granted)]
            },
        ]
    }
}
