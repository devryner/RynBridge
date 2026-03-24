package com.devryner.rynbridge.push.fcm

import com.devryner.rynbridge.core.*

class PushFCMModule(provider: PushFCMProvider) : BridgeModule {

    override val name = "push-fcm"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "getToken" to { _ ->
            val token = provider.getToken()
            FCMToken(token = token).toPayload()
        },
        "deleteToken" to { _ ->
            provider.deleteToken()
            emptyMap()
        },
        "subscribeToTopic" to { payload ->
            val topic = payload["topic"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: topic")
            provider.subscribeToTopic(topic)
            emptyMap()
        },
        "unsubscribeFromTopic" to { payload ->
            val topic = payload["topic"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: topic")
            provider.unsubscribeFromTopic(topic)
            emptyMap()
        },
        "getAutoInitEnabled" to { _ ->
            val enabled = provider.getAutoInitEnabled()
            FCMAutoInit(enabled = enabled).toPayload()
        },
        "setAutoInitEnabled" to { payload ->
            val enabled = payload["enabled"]?.boolValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: enabled")
            provider.setAutoInitEnabled(enabled)
            emptyMap()
        }
    )
}
