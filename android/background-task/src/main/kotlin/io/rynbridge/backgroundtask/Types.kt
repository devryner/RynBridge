package io.rynbridge.backgroundtask

import io.rynbridge.core.BridgeValue

interface BackgroundTaskProvider {
    suspend fun scheduleTask(taskId: String, type: String, interval: Int?, delay: Int?, requiresNetwork: Boolean, requiresCharging: Boolean): Boolean
    suspend fun cancelTask(taskId: String): Boolean
    suspend fun cancelAllTasks(): Boolean
    suspend fun getScheduledTasks(): List<Map<String, BridgeValue>>
    fun completeTask(taskId: String, success: Boolean)
    suspend fun requestPermission(): Boolean
}
