package com.devryner.rynbridge.core

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class EventEmitterTest {

    @Test
    fun `on and emit`() {
        val emitter = EventEmitter()
        var received: Map<String, BridgeValue>? = null

        emitter.on("test") { data -> received = data }

        emitter.emit("test", mapOf("value" to BridgeValue.string("hello")))
        assertEquals("hello", received?.get("value")?.stringValue)
    }

    @Test
    fun `multiple listeners`() {
        val emitter = EventEmitter()
        var count = 0

        emitter.on("event") { _ -> count++ }
        emitter.on("event") { _ -> count++ }

        emitter.emit("event", emptyMap())
        assertEquals(2, count)
    }

    @Test
    fun `off removes listener`() {
        val emitter = EventEmitter()
        var count = 0

        val id = emitter.on("event") { _ -> count++ }
        emitter.emit("event", emptyMap())
        assertEquals(1, count)

        emitter.off("event", id)
        emitter.emit("event", emptyMap())
        assertEquals(1, count)
    }

    @Test
    fun `removeAllListeners for event`() {
        val emitter = EventEmitter()
        var count = 0

        emitter.on("event1") { _ -> count++ }
        emitter.on("event1") { _ -> count++ }
        emitter.on("event2") { _ -> count++ }

        emitter.removeAllListeners("event1")
        emitter.emit("event1", emptyMap())
        assertEquals(0, count)

        emitter.emit("event2", emptyMap())
        assertEquals(1, count)
    }

    @Test
    fun `removeAllListeners removes all`() {
        val emitter = EventEmitter()
        var count = 0

        emitter.on("event1") { _ -> count++ }
        emitter.on("event2") { _ -> count++ }

        emitter.removeAllListeners()
        emitter.emit("event1", emptyMap())
        emitter.emit("event2", emptyMap())
        assertEquals(0, count)
    }

    @Test
    fun `listenerCount`() {
        val emitter = EventEmitter()
        emitter.on("event") { _ -> }
        emitter.on("event") { _ -> }
        assertEquals(2, emitter.listenerCount("event"))
        assertEquals(0, emitter.listenerCount("other"))
    }

    @Test
    fun `emit nonexistent event does not crash`() {
        val emitter = EventEmitter()
        emitter.emit("nonexistent", emptyMap())
    }
}
