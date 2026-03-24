package com.devryner.rynbridge.auth

import com.devryner.rynbridge.core.*

class AuthModule(provider: AuthProvider) : BridgeModule {

    override val name = "auth"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "login" to { payload ->
            val providerName = payload["provider"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: provider")
            val scopes = payload["scopes"]?.arrayValue
                ?.mapNotNull { it.stringValue }
                ?: emptyList()
            val result = provider.login(providerName, scopes)
            result.toPayload()
        },
        "logout" to { _ ->
            provider.logout()
            emptyMap()
        },
        "getToken" to { _ ->
            val result = provider.getToken()
            result.toPayload()
        },
        "refreshToken" to { _ ->
            val result = provider.refreshToken()
            result.toPayload()
        },
        "getUser" to { _ ->
            val user = provider.getUser()
            mapOf("user" to (user?.let { BridgeValue.dict(it.toPayload()) } ?: BridgeValue.nullValue()))
        }
    )
}
