package com.devryner.rynbridge.backgroundtask

import com.devryner.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class BackgroundTaskModuleTest {

    @Test
    fun `scheduleTask returns taskId and success`() = runTest {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        val handler = module.actions["scheduleTask"]!!

        val result = handler(mapOf(
            "taskId" to BridgeValue.string("task-1"),
            "type" to BridgeValue.string("periodic"),
            "interval" to BridgeValue.int(900),
            "delay" to BridgeValue.int(60),
            "requiresNetwork" to BridgeValue.bool(true),
            "requiresCharging" to BridgeValue.bool(false)
        ))
        assertEquals("task-1", result["taskId"]?.stringValue)
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("task-1", provider.lastScheduleTaskId)
        assertEquals("periodic", provider.lastScheduleType)
        assertEquals(true, provider.lastRequiresNetwork)
    }

    @Test
    fun `cancelTask returns success`() = runTest {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        val handler = module.actions["cancelTask"]!!

        val result = handler(mapOf("taskId" to BridgeValue.string("task-1")))
        assertEquals(true, result["success"]?.boolValue)
        assertEquals("task-1", provider.lastCancelTaskId)
    }

    @Test
    fun `cancelAllTasks returns success`() = runTest {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        val handler = module.actions["cancelAllTasks"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["success"]?.boolValue)
        assertTrue(provider.cancelAllCalled)
    }

    @Test
    fun `getScheduledTasks returns task list`() = runTest {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        val handler = module.actions["getScheduledTasks"]!!

        val result = handler(emptyMap())
        val tasks = result["tasks"]?.arrayValue
        assertNotNull(tasks)
        assertEquals(1, tasks!!.size)
        assertEquals("task-1", tasks[0].dictionaryValue?.get("taskId")?.stringValue)
    }

    @Test
    fun `completeTask calls provider`() = runTest {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        val handler = module.actions["completeTask"]!!

        val result = handler(mapOf(
            "taskId" to BridgeValue.string("task-1"),
            "success" to BridgeValue.bool(true)
        ))
        assertTrue(result.isEmpty())
        assertEquals("task-1", provider.lastCompleteTaskId)
        assertEquals(true, provider.lastCompleteSuccess)
    }

    @Test
    fun `completeTask defaults success to true`() = runTest {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        val handler = module.actions["completeTask"]!!

        handler(mapOf("taskId" to BridgeValue.string("task-2")))
        assertEquals("task-2", provider.lastCompleteTaskId)
        assertEquals(true, provider.lastCompleteSuccess)
    }

    @Test
    fun `requestPermission returns granted`() = runTest {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        val handler = module.actions["requestPermission"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["granted"]?.boolValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockBackgroundTaskProvider()
        val module = BackgroundTaskModule(provider)
        assertEquals("backgroundTask", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockBackgroundTaskProvider : BackgroundTaskProvider {
    var lastScheduleTaskId: String? = null
    var lastScheduleType: String? = null
    var lastRequiresNetwork: Boolean? = null
    var lastCancelTaskId: String? = null
    var cancelAllCalled = false
    var lastCompleteTaskId: String? = null
    var lastCompleteSuccess: Boolean? = null

    override suspend fun scheduleTask(
        taskId: String,
        type: String,
        interval: Int?,
        delay: Int?,
        requiresNetwork: Boolean,
        requiresCharging: Boolean
    ): Boolean {
        lastScheduleTaskId = taskId
        lastScheduleType = type
        lastRequiresNetwork = requiresNetwork
        return true
    }

    override suspend fun cancelTask(taskId: String): Boolean {
        lastCancelTaskId = taskId
        return true
    }

    override suspend fun cancelAllTasks(): Boolean {
        cancelAllCalled = true
        return true
    }

    override suspend fun getScheduledTasks(): List<Map<String, BridgeValue>> =
        listOf(mapOf(
            "taskId" to BridgeValue.string("task-1"),
            "type" to BridgeValue.string("periodic"),
            "status" to BridgeValue.string("scheduled")
        ))

    override fun completeTask(taskId: String, success: Boolean) {
        lastCompleteTaskId = taskId
        lastCompleteSuccess = success
    }

    override suspend fun requestPermission(): Boolean = true
}
