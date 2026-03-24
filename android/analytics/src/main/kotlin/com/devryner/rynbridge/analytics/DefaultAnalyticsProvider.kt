package com.devryner.rynbridge.analytics

import com.devryner.rynbridge.core.BridgeValue
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

class DefaultAnalyticsProvider : AnalyticsProvider {

    private val events = CopyOnWriteArrayList<Map<String, Any?>>()
    private val userProperties = ConcurrentHashMap<String, String>()
    @Volatile private var userId: String? = null
    @Volatile private var currentScreen: String? = null
    @Volatile private var enabled: Boolean = true

    override fun logEvent(name: String, params: Map<String, BridgeValue>) {
        if (!enabled) return
        events.add(
            mapOf(
                "name" to name,
                "params" to params,
                "screen" to currentScreen,
                "userId" to userId,
                "timestamp" to System.currentTimeMillis()
            )
        )
    }

    override fun setUserProperty(key: String, value: String) {
        userProperties[key] = value
    }

    override fun setUserId(userId: String) {
        this.userId = userId
    }

    override fun setScreen(name: String) {
        this.currentScreen = name
    }

    override fun resetUser() {
        userId = null
        currentScreen = null
        userProperties.clear()
    }

    override suspend fun setEnabled(enabled: Boolean): Boolean {
        this.enabled = enabled
        return this.enabled
    }

    override suspend fun isEnabled(): Boolean {
        return enabled
    }
}
