package io.rynbridge.analytics

import io.rynbridge.core.*

class AnalyticsModule(provider: AnalyticsProvider) : BridgeModule {
    constructor() : this(DefaultAnalyticsProvider())

    override val name = "analytics"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "logEvent" to { payload ->
            val eventName = payload["name"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: name")
            val params: Map<String, BridgeValue> = payload["params"]?.dictionaryValue ?: emptyMap()
            provider.logEvent(eventName, params)
            emptyMap()
        },
        "setUserProperty" to { payload ->
            val key = payload["key"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: key")
            val value = payload["value"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: value")
            provider.setUserProperty(key, value)
            emptyMap()
        },
        "setUserId" to { payload ->
            val userId = payload["userId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: userId")
            provider.setUserId(userId)
            emptyMap()
        },
        "setScreen" to { payload ->
            val screenName = payload["name"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: name")
            provider.setScreen(screenName)
            emptyMap()
        },
        "resetUser" to { _ ->
            provider.resetUser()
            emptyMap()
        },
        "setEnabled" to { payload ->
            val enabled = payload["enabled"]?.boolValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: enabled")
            val result = provider.setEnabled(enabled)
            mapOf("enabled" to BridgeValue.bool(result))
        },
        "isEnabled" to { _ ->
            val result = provider.isEnabled()
            mapOf("enabled" to BridgeValue.bool(result))
        }
    )
}
