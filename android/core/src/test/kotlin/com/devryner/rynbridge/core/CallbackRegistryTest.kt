package com.devryner.rynbridge.core

import kotlinx.coroutines.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class CallbackRegistryTest {

    @Test
    fun `resolve returns response`() = runTest {
        val registry = CallbackRegistry()
        val response = BridgeResponse(
            id = "req-1",
            status = ResponseStatus.success,
            payload = mapOf("value" to BridgeValue.string("hello"))
        )

        val deferred = async {
            registry.register(id = "req-1", timeout = 5000L, scope = this)
        }

        delay(50)
        val resolved = registry.resolve(id = "req-1", response = response)
        assertTrue(resolved)

        val actual = deferred.await()
        assertEquals("req-1", actual.id)
        assertEquals(ResponseStatus.success, actual.status)
        assertEquals("hello", actual.payload["value"]?.stringValue)
    }

    @Test
    fun `resolve non-existent ID returns false`() = runTest {
        val registry = CallbackRegistry()
        val response = BridgeResponse(id = "nonexistent", status = ResponseStatus.success)
        val resolved = registry.resolve(id = "nonexistent", response = response)
        assertFalse(resolved)
    }

    @Test
    fun `timeout throws error`() = runTest {
        val registry = CallbackRegistry()

        val exception = assertThrows(RynBridgeError::class.java) {
            runBlocking {
                registry.register(id = "timeout-req", timeout = 100L, scope = this)
            }
        }
        assertEquals(ErrorCode.TIMEOUT, exception.code)
    }

    @Test
    fun `clear cancels all pending`() = runTest {
        val registry = CallbackRegistry()
        var caughtError: RynBridgeError? = null

        val job = launch {
            try {
                registry.register(id = "clear-req", timeout = 10000L, scope = this)
            } catch (e: RynBridgeError) {
                caughtError = e
            }
        }

        delay(50)
        registry.clear()
        job.join()

        assertNotNull(caughtError)
        assertEquals(ErrorCode.TRANSPORT_ERROR, caughtError!!.code)
    }

    @Test
    fun `pending count`() = runTest {
        val registry = CallbackRegistry()

        val job1 = launch { try { registry.register(id = "a", timeout = 10000L, scope = this) } catch (_: Exception) {} }
        val job2 = launch { try { registry.register(id = "b", timeout = 10000L, scope = this) } catch (_: Exception) {} }

        delay(50)
        assertEquals(2, registry.pendingCount())

        registry.clear()
        job1.join()
        job2.join()
    }
}
