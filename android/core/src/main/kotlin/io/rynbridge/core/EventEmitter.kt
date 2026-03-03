package io.rynbridge.core

class EventEmitter {

    private val lock = Any()
    private val listeners = mutableMapOf<String, MutableList<ListenerEntry>>()
    private var nextId: Long = 0

    fun on(event: String, handler: (Map<String, BridgeValue>) -> Unit): Long {
        synchronized(lock) {
            val id = nextId++
            listeners.getOrPut(event) { mutableListOf() }
                .add(ListenerEntry(id, handler))
            return id
        }
    }

    fun off(event: String, id: Long) {
        synchronized(lock) {
            listeners[event]?.removeAll { it.id == id }
            if (listeners[event]?.isEmpty() == true) {
                listeners.remove(event)
            }
        }
    }

    fun emit(event: String, data: Map<String, BridgeValue>) {
        val entries = synchronized(lock) {
            listeners[event]?.toList() ?: emptyList()
        }
        for (entry in entries) {
            entry.handler(data)
        }
    }

    fun removeAllListeners(event: String? = null) {
        synchronized(lock) {
            if (event != null) {
                listeners.remove(event)
            } else {
                listeners.clear()
            }
        }
    }

    fun listenerCount(event: String): Int {
        synchronized(lock) {
            return listeners[event]?.size ?: 0
        }
    }

    private data class ListenerEntry(
        val id: Long,
        val handler: (Map<String, BridgeValue>) -> Unit
    )
}
