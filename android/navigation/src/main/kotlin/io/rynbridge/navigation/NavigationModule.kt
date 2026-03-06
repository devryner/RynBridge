package io.rynbridge.navigation

import io.rynbridge.core.*

class NavigationModule(provider: NavigationProvider) : BridgeModule {

    override val name = "navigation"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "push" to { payload ->
            val screen = payload["screen"]?.stringValue ?: ""
            val params = payload["params"]?.dictionaryValue
            val result = provider.push(screen, params)
            result.toPayload()
        },
        "pop" to { _ ->
            val result = provider.pop()
            result.toPayload()
        },
        "popToRoot" to { _ ->
            val result = provider.popToRoot()
            result.toPayload()
        },
        "present" to { payload ->
            val screen = payload["screen"]?.stringValue ?: ""
            val style = payload["style"]?.stringValue
            val params = payload["params"]?.dictionaryValue
            val result = provider.present(screen, style, params)
            result.toPayload()
        },
        "dismiss" to { _ ->
            val result = provider.dismiss()
            result.toPayload()
        },
        "openURL" to { payload ->
            val url = payload["url"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: url")
            val result = provider.openURL(url)
            result.toPayload()
        },
        "canOpenURL" to { payload ->
            val url = payload["url"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: url")
            val result = provider.canOpenURL(url)
            result.toPayload()
        },
        "getInitialURL" to { _ ->
            val result = provider.getInitialURL()
            result.toPayload()
        },
        "getAppState" to { _ ->
            val result = provider.getAppState()
            result.toPayload()
        }
    )
}
