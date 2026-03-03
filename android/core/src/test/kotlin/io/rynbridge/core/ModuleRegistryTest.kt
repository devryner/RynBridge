package io.rynbridge.core

import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class ModuleRegistryTest {

    @Test
    fun `register and get action`() = runTest {
        val registry = ModuleRegistry()
        val module = TestModule(
            name = "test",
            version = "0.1.0",
            actions = mapOf("doSomething" to { _ -> mapOf("result" to BridgeValue.string("done")) })
        )
        registry.register(module)

        val handler = registry.getAction(module = "test", action = "doSomething")
        assertNotNull(handler)
    }

    @Test
    fun `module not found`() {
        val registry = ModuleRegistry()
        val exception = assertThrows(RynBridgeError::class.java) {
            registry.getAction(module = "missing", action = "doSomething")
        }
        assertEquals(ErrorCode.MODULE_NOT_FOUND, exception.code)
    }

    @Test
    fun `action not found`() {
        val registry = ModuleRegistry()
        val module = TestModule(name = "test", version = "0.1.0", actions = emptyMap())
        registry.register(module)

        val exception = assertThrows(RynBridgeError::class.java) {
            registry.getAction(module = "test", action = "missing")
        }
        assertEquals(ErrorCode.ACTION_NOT_FOUND, exception.code)
    }

    @Test
    fun `hasModule`() {
        val registry = ModuleRegistry()
        val module = TestModule(name = "test", version = "0.1.0", actions = emptyMap())
        assertFalse(registry.hasModule("test"))
        registry.register(module)
        assertTrue(registry.hasModule("test"))
    }

    @Test
    fun `register overwrites existing`() = runTest {
        val registry = ModuleRegistry()
        val module1 = TestModule(
            name = "test",
            version = "0.1.0",
            actions = mapOf("action1" to { _ -> emptyMap() })
        )
        val module2 = TestModule(
            name = "test",
            version = "0.2.0",
            actions = mapOf("action2" to { _ -> emptyMap() })
        )

        registry.register(module1)
        registry.register(module2)

        assertThrows(RynBridgeError::class.java) {
            registry.getAction(module = "test", action = "action1")
        }
        assertNotNull(registry.getAction(module = "test", action = "action2"))
    }
}

private class TestModule(
    override val name: String,
    override val version: String,
    override val actions: Map<String, ActionHandler>
) : BridgeModule
