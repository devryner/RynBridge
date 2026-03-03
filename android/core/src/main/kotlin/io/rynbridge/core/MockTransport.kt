package io.rynbridge.core

class MockTransport : Transport {

    private val lock = Any()
    private val _sent = mutableListOf<String>()
    private var messageHandler: ((String) -> Unit)? = null

    val sent: List<String>
        get() = synchronized(lock) { _sent.toList() }

    override fun send(message: String) {
        synchronized(lock) {
            _sent.add(message)
        }
    }

    override fun onMessage(handler: (String) -> Unit) {
        synchronized(lock) {
            messageHandler = handler
        }
    }

    override fun dispose() {
        synchronized(lock) {
            messageHandler = null
        }
    }

    fun simulateIncoming(message: String) {
        val handler = synchronized(lock) { messageHandler }
        handler?.invoke(message)
    }

    fun reset() {
        synchronized(lock) {
            _sent.clear()
        }
    }
}
