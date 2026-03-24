package com.devryner.rynbridge.auth

import com.devryner.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class AuthModuleTest {

    @Test
    fun `login returns login result`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["login"]!!

        val result = handler(mapOf(
            "provider" to BridgeValue.string("google"),
            "scopes" to BridgeValue.array(listOf(BridgeValue.string("email"), BridgeValue.string("profile")))
        ))
        assertEquals("mock-token-123", result["token"]?.stringValue)
        assertEquals("mock-refresh-456", result["refreshToken"]?.stringValue)
        assertEquals("2026-12-31T23:59:59Z", result["expiresAt"]?.stringValue)
        assertNotNull(result["user"]?.dictionaryValue)
    }

    @Test
    fun `login passes provider and scopes`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["login"]!!

        handler(mapOf(
            "provider" to BridgeValue.string("apple"),
            "scopes" to BridgeValue.array(listOf(BridgeValue.string("openid")))
        ))
        assertEquals("apple", provider.lastLoginProvider)
        assertEquals(listOf("openid"), provider.lastLoginScopes)
    }

    @Test
    fun `login without scopes defaults to empty`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["login"]!!

        handler(mapOf("provider" to BridgeValue.string("google")))
        assertEquals(emptyList<String>(), provider.lastLoginScopes)
    }

    @Test
    fun `login missing provider throws`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["login"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `logout returns empty`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["logout"]!!

        val result = handler(emptyMap())
        assertTrue(result.isEmpty())
        assertTrue(provider.logoutCalled)
    }

    @Test
    fun `getToken returns token result`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["getToken"]!!

        val result = handler(emptyMap())
        assertEquals("current-token-789", result["token"]?.stringValue)
        assertEquals("2026-12-31T23:59:59Z", result["expiresAt"]?.stringValue)
    }

    @Test
    fun `refreshToken returns new login result`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["refreshToken"]!!

        val result = handler(emptyMap())
        assertEquals("refreshed-token-000", result["token"]?.stringValue)
        assertEquals("2027-01-01T00:00:00Z", result["expiresAt"]?.stringValue)
    }

    @Test
    fun `getUser returns user data`() = runTest {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        val handler = module.actions["getUser"]!!

        val result = handler(emptyMap())
        val user = result["user"]?.dictionaryValue
        assertNotNull(user)
        assertEquals("user-1", user?.get("id")?.stringValue)
        assertEquals("test@example.com", user?.get("email")?.stringValue)
        assertEquals("Test User", user?.get("name")?.stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockAuthProvider()
        val module = AuthModule(provider)
        assertEquals("auth", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockAuthProvider()
        bridge.register(AuthModule(provider))

        val requestJSON = """{"id":"req-1","module":"auth","action":"getToken","payload":{},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        transport.awaitSent(1)

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertEquals("current-token-789", response.payload["token"]?.stringValue)

        bridge.dispose()
    }
}

private class MockAuthProvider : AuthProvider {
    var lastLoginProvider: String? = null
    var lastLoginScopes: List<String>? = null
    var logoutCalled = false

    override suspend fun login(provider: String, scopes: List<String>): LoginResult {
        lastLoginProvider = provider
        lastLoginScopes = scopes
        return LoginResult(
            token = "mock-token-123",
            refreshToken = "mock-refresh-456",
            expiresAt = "2026-12-31T23:59:59Z",
            user = AuthUser(id = "user-1", email = "test@example.com", name = "Test User", profileImage = null)
        )
    }

    override suspend fun logout() {
        logoutCalled = true
    }

    override suspend fun getToken(): TokenResult {
        return TokenResult(token = "current-token-789", expiresAt = "2026-12-31T23:59:59Z")
    }

    override suspend fun refreshToken(): LoginResult {
        return LoginResult(
            token = "refreshed-token-000",
            refreshToken = null,
            expiresAt = "2027-01-01T00:00:00Z",
            user = null
        )
    }

    override suspend fun getUser(): AuthUser? {
        return AuthUser(id = "user-1", email = "test@example.com", name = "Test User", profileImage = null)
    }
}
