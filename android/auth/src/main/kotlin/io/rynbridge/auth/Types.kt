package io.rynbridge.auth

import io.rynbridge.core.BridgeValue

data class AuthUser(
    val id: String,
    val email: String?,
    val name: String?,
    val profileImage: String?
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id),
        "email" to (email?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "name" to (name?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "profileImage" to (profileImage?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue())
    )
}

data class LoginResult(
    val token: String,
    val refreshToken: String?,
    val expiresAt: String,
    val user: AuthUser?
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "token" to BridgeValue.string(token),
        "refreshToken" to (refreshToken?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "expiresAt" to BridgeValue.string(expiresAt),
        "user" to (user?.let { BridgeValue.dict(it.toPayload()) } ?: BridgeValue.nullValue())
    )
}

data class TokenResult(
    val token: String?,
    val expiresAt: String?
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "token" to (token?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "expiresAt" to (expiresAt?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue())
    )
}

data class AuthStateEvent(
    val authenticated: Boolean,
    val user: AuthUser?
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "authenticated" to BridgeValue.bool(authenticated),
        "user" to (user?.let { BridgeValue.dict(it.toPayload()) } ?: BridgeValue.nullValue())
    )
}

interface AuthProvider {
    suspend fun login(provider: String, scopes: List<String>): LoginResult
    suspend fun logout()
    suspend fun getToken(): TokenResult
    suspend fun refreshToken(): LoginResult
    suspend fun getUser(): AuthUser?
}
