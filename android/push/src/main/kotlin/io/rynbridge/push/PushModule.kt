package io.rynbridge.push

import io.rynbridge.core.*

class PushModule(provider: PushProvider) : BridgeModule {

    override val name = "push"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "register" to { _ ->
            val result = provider.register()
            result.toPayload()
        },
        "unregister" to { _ ->
            provider.unregister()
            emptyMap()
        },
        "getToken" to { _ ->
            val token = provider.getToken()
            mapOf("token" to (token?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()))
        },
        "requestPermission" to { _ ->
            val granted = provider.requestPermission()
            mapOf("granted" to BridgeValue.bool(granted))
        },
        "getPermissionStatus" to { _ ->
            val result = provider.getPermissionStatus()
            result.toPayload()
        },
        "getInitialNotification" to { _ ->
            val notification = provider.getInitialNotification()
            notification?.toPayload() ?: mapOf(
                "title" to BridgeValue.nullValue(),
                "body" to BridgeValue.nullValue(),
                "data" to BridgeValue.nullValue()
            )
        }
    )
}
