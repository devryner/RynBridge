package io.rynbridge.crypto

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class CryptoModuleTest {

    @Test
    fun `generateKeyPair returns public key`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["generateKeyPair"]!!

        val result = handler(emptyMap())
        assertEquals("mock-public-key-abc", result["publicKey"]?.stringValue)
    }

    @Test
    fun `performKeyExchange returns session established`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["performKeyExchange"]!!

        val result = handler(mapOf("remotePublicKey" to BridgeValue.string("remote-key-xyz")))
        assertEquals(true, result["sessionEstablished"]?.boolValue)
        assertEquals("remote-key-xyz", provider.lastRemotePublicKey)
    }

    @Test
    fun `performKeyExchange missing remotePublicKey throws`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["performKeyExchange"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `encrypt returns encrypt result`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["encrypt"]!!

        val result = handler(mapOf(
            "data" to BridgeValue.string("hello world"),
            "associatedData" to BridgeValue.string("aad-123")
        ))
        assertEquals("mock-ciphertext", result["ciphertext"]?.stringValue)
        assertEquals("mock-iv", result["iv"]?.stringValue)
        assertEquals("mock-tag", result["tag"]?.stringValue)
        assertEquals("hello world", provider.lastEncryptData)
        assertEquals("aad-123", provider.lastEncryptAssociatedData)
    }

    @Test
    fun `encrypt without associated data`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["encrypt"]!!

        handler(mapOf("data" to BridgeValue.string("secret")))
        assertNull(provider.lastEncryptAssociatedData)
    }

    @Test
    fun `encrypt missing data throws`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["encrypt"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `decrypt returns plaintext`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["decrypt"]!!

        val result = handler(mapOf(
            "ciphertext" to BridgeValue.string("mock-ciphertext"),
            "iv" to BridgeValue.string("mock-iv"),
            "tag" to BridgeValue.string("mock-tag"),
            "associatedData" to BridgeValue.string("aad-123")
        ))
        assertEquals("decrypted-plaintext", result["plaintext"]?.stringValue)
        assertEquals("aad-123", provider.lastDecryptAssociatedData)
    }

    @Test
    fun `decrypt without associated data`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["decrypt"]!!

        handler(mapOf(
            "ciphertext" to BridgeValue.string("ct"),
            "iv" to BridgeValue.string("iv"),
            "tag" to BridgeValue.string("tag")
        ))
        assertNull(provider.lastDecryptAssociatedData)
    }

    @Test
    fun `decrypt missing required fields throws`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["decrypt"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest {
                handler(mapOf("ciphertext" to BridgeValue.string("ct")))
            }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `getStatus returns crypto status`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["getStatus"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["initialized"]?.boolValue)
        assertEquals("2026-01-01T00:00:00Z", result["keyCreatedAt"]?.stringValue)
        assertEquals("AES-256-GCM", result["algorithm"]?.stringValue)
    }

    @Test
    fun `rotateKeys returns new public key`() = runTest {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        val handler = module.actions["rotateKeys"]!!

        val result = handler(emptyMap())
        assertEquals("rotated-public-key-def", result["publicKey"]?.stringValue)
        assertTrue(provider.rotateKeysCalled)
    }

    @Test
    fun `module name and version`() {
        val provider = MockCryptoProvider()
        val module = CryptoModule(provider)
        assertEquals("crypto", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockCryptoProvider()
        bridge.register(CryptoModule(provider))

        val requestJSON = """{"id":"req-1","module":"crypto","action":"getStatus","payload":{},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        transport.awaitSent(1)

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertEquals(true, response.payload["initialized"]?.boolValue)
        assertEquals("AES-256-GCM", response.payload["algorithm"]?.stringValue)

        bridge.dispose()
    }
}

private class MockCryptoProvider : CryptoProvider {
    var lastRemotePublicKey: String? = null
    var lastEncryptData: String? = null
    var lastEncryptAssociatedData: String? = null
    var lastDecryptAssociatedData: String? = null
    var rotateKeysCalled = false

    override suspend fun generateKeyPair(): String {
        return "mock-public-key-abc"
    }

    override suspend fun performKeyExchange(remotePublicKey: String): Boolean {
        lastRemotePublicKey = remotePublicKey
        return true
    }

    override suspend fun encrypt(data: String, associatedData: String?): EncryptResult {
        lastEncryptData = data
        lastEncryptAssociatedData = associatedData
        return EncryptResult(ciphertext = "mock-ciphertext", iv = "mock-iv", tag = "mock-tag")
    }

    override suspend fun decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?): String {
        lastDecryptAssociatedData = associatedData
        return "decrypted-plaintext"
    }

    override suspend fun getStatus(): CryptoStatus {
        return CryptoStatus(initialized = true, keyCreatedAt = "2026-01-01T00:00:00Z", algorithm = "AES-256-GCM")
    }

    override suspend fun rotateKeys(): String {
        rotateKeysCalled = true
        return "rotated-public-key-def"
    }
}
