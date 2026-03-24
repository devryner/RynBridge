package com.devryner.rynbridge.playground.providers

import com.devryner.rynbridge.auth.*
import java.time.Instant
import java.util.UUID

class MockAuthProvider : AuthProvider {
    private var currentToken: String? = null

    override suspend fun login(provider: String, scopes: List<String>): LoginResult {
        val token = "mock_token_${UUID.randomUUID().toString().take(8)}"
        currentToken = token
        return LoginResult(
            token = token,
            refreshToken = "mock_refresh_${UUID.randomUUID().toString().take(8)}",
            expiresAt = Instant.now().plusSeconds(3600).toString(),
            user = AuthUser(id = "user_1", email = "test@example.com", name = "Test User", profileImage = null)
        )
    }

    override suspend fun logout() {
        currentToken = null
    }

    override suspend fun getToken(): TokenResult {
        return TokenResult(
            token = currentToken,
            expiresAt = if (currentToken != null) Instant.now().plusSeconds(3600).toString() else null
        )
    }

    override suspend fun refreshToken(): LoginResult {
        return login("refresh", emptyList())
    }

    override suspend fun getUser(): AuthUser? {
        if (currentToken == null) return null
        return AuthUser(id = "user_1", email = "test@example.com", name = "Test User", profileImage = null)
    }
}
