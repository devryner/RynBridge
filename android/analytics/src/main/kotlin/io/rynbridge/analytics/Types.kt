package io.rynbridge.analytics

import io.rynbridge.core.BridgeValue

interface AnalyticsProvider {
    fun logEvent(name: String, params: Map<String, BridgeValue>)
    fun setUserProperty(key: String, value: String)
    fun setUserId(userId: String)
    fun setScreen(name: String)
    fun resetUser()
    suspend fun setEnabled(enabled: Boolean): Boolean
    suspend fun isEnabled(): Boolean
}
