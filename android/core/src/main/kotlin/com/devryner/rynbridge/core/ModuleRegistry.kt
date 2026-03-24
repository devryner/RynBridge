package com.devryner.rynbridge.core

class ModuleRegistry {

    private val lock = Any()
    private val modules = mutableMapOf<String, BridgeModule>()

    fun register(module: BridgeModule) {
        synchronized(lock) {
            modules[module.name] = module
        }
    }

    fun getAction(module: String, action: String): ActionHandler {
        synchronized(lock) {
            val mod = modules[module]
                ?: throw RynBridgeError(
                    code = ErrorCode.MODULE_NOT_FOUND,
                    message = "Module '$module' not found"
                )
            return mod.actions[action]
                ?: throw RynBridgeError(
                    code = ErrorCode.ACTION_NOT_FOUND,
                    message = "Action '$action' not found in module '$module'"
                )
        }
    }

    fun hasModule(name: String): Boolean {
        synchronized(lock) {
            return modules.containsKey(name)
        }
    }
}
