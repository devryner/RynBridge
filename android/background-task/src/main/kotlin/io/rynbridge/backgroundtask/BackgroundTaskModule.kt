package io.rynbridge.backgroundtask

import io.rynbridge.core.*

class BackgroundTaskModule(provider: BackgroundTaskProvider) : BridgeModule {

    override val name = "backgroundTask"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "scheduleTask" to { payload ->
            val taskId = payload["taskId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: taskId")
            val type = payload["type"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: type")
            val interval = payload["interval"]?.intValue?.toInt()
            val delay = payload["delay"]?.intValue?.toInt()
            val requiresNetwork = payload["requiresNetwork"]?.boolValue ?: false
            val requiresCharging = payload["requiresCharging"]?.boolValue ?: false
            val success = provider.scheduleTask(taskId, type, interval, delay, requiresNetwork, requiresCharging)
            mapOf("taskId" to BridgeValue.string(taskId), "success" to BridgeValue.bool(success))
        },
        "cancelTask" to { payload ->
            val taskId = payload["taskId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: taskId")
            val success = provider.cancelTask(taskId)
            mapOf("success" to BridgeValue.bool(success))
        },
        "cancelAllTasks" to { _ ->
            val success = provider.cancelAllTasks()
            mapOf("success" to BridgeValue.bool(success))
        },
        "getScheduledTasks" to { _ ->
            val tasks = provider.getScheduledTasks()
            mapOf("tasks" to BridgeValue.array(tasks.map { BridgeValue.dict(it) }))
        },
        "completeTask" to { payload ->
            val taskId = payload["taskId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: taskId")
            val success = payload["success"]?.boolValue ?: true
            provider.completeTask(taskId, success)
            emptyMap()
        },
        "requestPermission" to { _ ->
            val granted = provider.requestPermission()
            mapOf("granted" to BridgeValue.bool(granted))
        }
    )
}
