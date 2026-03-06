package io.rynbridge.playground.providers

import io.rynbridge.crypto.*
import java.time.Instant
import java.util.Base64
import java.util.UUID

class MockCryptoProvider : CryptoProvider {
    override suspend fun generateKeyPair(): String {
        return "mock_public_key_${UUID.randomUUID().toString().take(16)}"
    }

    override suspend fun performKeyExchange(remotePublicKey: String): Boolean {
        return true
    }

    override suspend fun encrypt(data: String, associatedData: String?): EncryptResult {
        return EncryptResult(
            ciphertext = Base64.getEncoder().encodeToString(data.toByteArray()),
            iv = UUID.randomUUID().toString().take(24),
            tag = UUID.randomUUID().toString().take(32)
        )
    }

    override suspend fun decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?): String {
        return try {
            String(Base64.getDecoder().decode(ciphertext))
        } catch (_: Exception) {
            "decrypted_data"
        }
    }

    override suspend fun getStatus(): CryptoStatus {
        return CryptoStatus(
            initialized = true,
            keyCreatedAt = Instant.now().toString(),
            algorithm = "AES-256-GCM"
        )
    }

    override suspend fun rotateKeys(): String {
        return "mock_rotated_key_${UUID.randomUUID().toString().take(16)}"
    }
}
