package io.rynbridge.core

import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class CallbackRegistry {

    private val mutex = Mutex()
    private val callbacks = mutableMapOf<String, CancellableContinuation<BridgeResponse>>()
    private val timeoutJobs = mutableMapOf<String, Job>()

    suspend fun register(id: String, timeout: Long, scope: CoroutineScope): BridgeResponse {
        return suspendCancellableCoroutine { continuation ->
            scope.launch {
                mutex.withLock {
                    callbacks[id] = continuation
                }

                val timeoutJob = scope.launch {
                    delay(timeout)
                    handleTimeout(id)
                }

                mutex.withLock {
                    timeoutJobs[id] = timeoutJob
                }

                continuation.invokeOnCancellation {
                    scope.launch {
                        mutex.withLock {
                            callbacks.remove(id)
                            timeoutJobs.remove(id)?.cancel()
                        }
                    }
                }
            }
        }
    }

    private suspend fun handleTimeout(id: String) {
        mutex.withLock {
            val continuation = callbacks.remove(id) ?: return
            timeoutJobs.remove(id)?.cancel()
            continuation.resumeWithException(
                RynBridgeError(code = ErrorCode.TIMEOUT, message = "Request $id timed out")
            )
        }
    }

    suspend fun resolve(id: String, response: BridgeResponse): Boolean {
        mutex.withLock {
            val continuation = callbacks.remove(id) ?: return false
            timeoutJobs.remove(id)?.cancel()
            continuation.resume(response)
            return true
        }
    }

    suspend fun clear() {
        mutex.withLock {
            for ((id, continuation) in callbacks) {
                continuation.resumeWithException(
                    RynBridgeError(
                        code = ErrorCode.TRANSPORT_ERROR,
                        message = "Bridge disposed, request $id cancelled"
                    )
                )
            }
            callbacks.clear()
            for ((_, job) in timeoutJobs) {
                job.cancel()
            }
            timeoutJobs.clear()
        }
    }

    suspend fun pendingCount(): Int {
        mutex.withLock {
            return callbacks.size
        }
    }
}
