package io.rynbridge.backgroundtask

import android.content.Context
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.rynbridge.core.BridgeValue
import java.util.concurrent.TimeUnit

class DefaultBackgroundTaskProvider(private val context: Context) : BackgroundTaskProvider {

    private val workManager: WorkManager by lazy { WorkManager.getInstance(context) }

    override suspend fun scheduleTask(
        taskId: String,
        type: String,
        interval: Int?,
        delay: Int?,
        requiresNetwork: Boolean,
        requiresCharging: Boolean
    ): Boolean {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(
                if (requiresNetwork) NetworkType.CONNECTED else NetworkType.NOT_REQUIRED
            )
            .setRequiresCharging(requiresCharging)
            .build()

        val inputData = Data.Builder()
            .putString("taskId", taskId)
            .putString("type", type)
            .build()

        if (type == "periodic" && interval != null) {
            val request = PeriodicWorkRequestBuilder<RynBridgeWorker>(
                interval.toLong(), TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .setInputData(inputData)
                .addTag(taskId)
                .build()

            workManager.enqueueUniquePeriodicWork(
                taskId,
                ExistingPeriodicWorkPolicy.REPLACE,
                request
            )
        } else {
            val requestBuilder = OneTimeWorkRequestBuilder<RynBridgeWorker>()
                .setConstraints(constraints)
                .setInputData(inputData)
                .addTag(taskId)

            if (delay != null && delay > 0) {
                requestBuilder.setInitialDelay(delay.toLong(), TimeUnit.SECONDS)
            }

            workManager.enqueueUniqueWork(
                taskId,
                ExistingWorkPolicy.REPLACE,
                requestBuilder.build()
            )
        }

        return true
    }

    override suspend fun cancelTask(taskId: String): Boolean {
        workManager.cancelUniqueWork(taskId)
        return true
    }

    override suspend fun cancelAllTasks(): Boolean {
        workManager.cancelAllWork()
        return true
    }

    override suspend fun getScheduledTasks(): List<Map<String, BridgeValue>> {
        val workInfos = workManager.getWorkInfosByTag("rynbridge").get()
        return workInfos.map { info ->
            mapOf(
                "taskId" to BridgeValue.string(info.tags.firstOrNull() ?: ""),
                "state" to BridgeValue.string(
                    when (info.state) {
                        WorkInfo.State.ENQUEUED -> "scheduled"
                        WorkInfo.State.RUNNING -> "running"
                        WorkInfo.State.SUCCEEDED -> "completed"
                        WorkInfo.State.FAILED -> "failed"
                        WorkInfo.State.CANCELLED -> "cancelled"
                        WorkInfo.State.BLOCKED -> "blocked"
                    }
                )
            )
        }
    }

    override fun completeTask(taskId: String, success: Boolean) {
        // WorkManager handles task completion automatically via Worker.Result
        // This is a no-op for WorkManager-based implementation
    }

    override suspend fun requestPermission(): Boolean {
        // WorkManager doesn't require special permissions
        return true
    }
}

class RynBridgeWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        // The actual task execution logic should be provided by the host app
        // via a registered callback. This worker serves as the scheduling entry point.
        return Result.success()
    }
}
