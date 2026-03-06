package io.rynbridge.core

import kotlinx.coroutines.*

class RynBridge(
    private val transport: Transport,
    private val config: BridgeConfig = BridgeConfig.DEFAULT
) {
    private val serializer = MessageSerializer(version = config.version)
    private val deserializer = MessageDeserializer()
    private val callbacks = CallbackRegistry()
    private val events = EventEmitter()
    private val modules = ModuleRegistry()
    private val versionNegotiator = VersionNegotiator()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    @Volatile
    private var disposed = false

    init {
        transport.onMessage { raw ->
            scope.launch { handleIncomingMessage(raw) }
        }
    }

    fun register(module: BridgeModule) {
        modules.register(module)
    }

    suspend fun call(
        module: String,
        action: String,
        payload: Map<String, BridgeValue> = emptyMap()
    ): Map<String, BridgeValue> {
        if (disposed) {
            throw RynBridgeError(code = ErrorCode.TRANSPORT_ERROR, message = "Bridge has been disposed")
        }

        val request = serializer.createRequest(module, action, payload)
        val json = serializer.serialize(request)

        transport.send(json)

        val response = callbacks.register(id = request.id, timeout = config.timeout, scope = scope)

        if (response.status == ResponseStatus.error && response.error != null) {
            val errorCode = ErrorCode.entries.find { it.code == response.error.code } ?: ErrorCode.UNKNOWN
            throw RynBridgeError(
                code = errorCode,
                message = response.error.message,
                details = response.error.details
            )
        }

        return response.payload
    }

    fun send(
        module: String,
        action: String,
        payload: Map<String, BridgeValue> = emptyMap()
    ) {
        if (disposed) return

        val request = serializer.createRequest(module, action, payload)
        val json = try { serializer.serialize(request) } catch (_: Exception) { return }

        transport.send(json)
    }

    fun onEvent(event: String, handler: (Map<String, BridgeValue>) -> Unit): Long {
        return events.on(event, handler)
    }

    fun offEvent(event: String, id: Long) {
        events.off(event, id)
    }

    fun emitEvent(
        module: String,
        action: String,
        payload: Map<String, BridgeValue> = emptyMap()
    ) {
        if (disposed) return
        val request = serializer.createRequest(module, action, payload)
        val json = try { serializer.serialize(request) } catch (_: Exception) { return }
        transport.send(json)
    }

    private suspend fun handleIncomingMessage(raw: String) {
        try {
            when (val message = deserializer.deserialize(raw)) {
                is IncomingMessage.Response -> {
                    callbacks.resolve(id = message.response.id, response = message.response)
                }
                is IncomingMessage.Request -> {
                    handleIncomingRequest(message.request)
                }
            }
        } catch (_: Exception) {
            // Malformed messages are silently dropped
        }
    }

    private suspend fun handleIncomingRequest(request: BridgeRequest) {
        try {
            versionNegotiator.assertCompatible(local = config.version, remote = request.version)

            val handler = modules.getAction(module = request.module, action = request.action)
            val result = handler(request.payload)

            val response = serializer.createResponse(id = request.id, status = ResponseStatus.success, payload = result)
            val json = serializer.serialize(response)
            transport.send(json)
        } catch (e: RynBridgeError) {
            sendErrorResponse(id = request.id, error = e)
        } catch (e: Exception) {
            sendErrorResponse(
                id = request.id,
                error = RynBridgeError(code = ErrorCode.UNKNOWN, message = e.message ?: "Unknown error")
            )
        }
    }

    private fun sendErrorResponse(id: String, error: RynBridgeError) {
        val response = serializer.createResponse(
            id = id,
            status = ResponseStatus.error,
            error = error.errorData
        )
        val json = try { serializer.serialize(response) } catch (_: Exception) { return }
        transport.send(json)
    }

    fun dispose() {
        disposed = true
        scope.launch { callbacks.clear() }
        events.removeAllListeners()
        transport.dispose()
        scope.cancel()
    }
}
