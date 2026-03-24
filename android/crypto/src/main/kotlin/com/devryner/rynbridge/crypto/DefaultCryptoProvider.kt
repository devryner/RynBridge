package com.devryner.rynbridge.crypto

import com.devryner.rynbridge.core.ErrorCode
import com.devryner.rynbridge.core.RynBridgeError
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.PublicKey
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec
import java.security.spec.X509EncodedKeySpec
import java.time.Instant
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyAgreement
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

class DefaultCryptoProvider : CryptoProvider {

    private var keyPair = generateECKeyPair()
    private var symmetricKey: SecretKey? = null
    private var keyCreatedAt: Instant = Instant.now()

    private fun generateECKeyPair(): java.security.KeyPair {
        val generator = KeyPairGenerator.getInstance("EC")
        generator.initialize(ECGenParameterSpec("secp256r1"))
        return generator.generateKeyPair()
    }

    override suspend fun generateKeyPair(): String {
        keyPair = generateECKeyPair()
        keyCreatedAt = Instant.now()
        symmetricKey = null
        return Base64.getEncoder().encodeToString(keyPair.public.encoded)
    }

    override suspend fun performKeyExchange(remotePublicKey: String): Boolean {
        val remoteKeyBytes = Base64.getDecoder().decode(remotePublicKey)
        val keyFactory = KeyFactory.getInstance("EC")
        val remoteKey = keyFactory.generatePublic(X509EncodedKeySpec(remoteKeyBytes))

        val agreement = KeyAgreement.getInstance("ECDH")
        agreement.init(keyPair.private)
        agreement.doPhase(remoteKey, true)
        val sharedSecret = agreement.generateSecret()

        // Derive 256-bit key from shared secret using first 32 bytes of SHA-256
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        digest.update("RynBridge".toByteArray())
        digest.update(sharedSecret)
        val derivedKey = digest.digest()
        symmetricKey = SecretKeySpec(derivedKey, "AES")
        return true
    }

    override suspend fun encrypt(data: String, associatedData: String?): EncryptResult {
        val key = symmetricKey
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Key exchange not performed. Call performKeyExchange first.")

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)

        associatedData?.let { cipher.updateAAD(it.toByteArray()) }

        val ciphertext = cipher.doFinal(data.toByteArray())
        val iv = cipher.iv
        val tagLength = 16
        val encryptedData = ciphertext.copyOfRange(0, ciphertext.size - tagLength)
        val tag = ciphertext.copyOfRange(ciphertext.size - tagLength, ciphertext.size)

        return EncryptResult(
            ciphertext = Base64.getEncoder().encodeToString(encryptedData),
            iv = Base64.getEncoder().encodeToString(iv),
            tag = Base64.getEncoder().encodeToString(tag)
        )
    }

    override suspend fun decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?): String {
        val key = symmetricKey
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Key exchange not performed. Call performKeyExchange first.")

        val ciphertextBytes = Base64.getDecoder().decode(ciphertext)
        val ivBytes = Base64.getDecoder().decode(iv)
        val tagBytes = Base64.getDecoder().decode(tag)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(128, ivBytes)
        cipher.init(Cipher.DECRYPT_MODE, key, spec)

        associatedData?.let { cipher.updateAAD(it.toByteArray()) }

        val combined = ciphertextBytes + tagBytes
        val plaintext = cipher.doFinal(combined)
        return String(plaintext)
    }

    override suspend fun getStatus(): CryptoStatus {
        return CryptoStatus(
            initialized = symmetricKey != null,
            keyCreatedAt = keyCreatedAt.toString(),
            algorithm = "AES-256-GCM"
        )
    }

    override suspend fun rotateKeys(): String {
        keyPair = generateECKeyPair()
        keyCreatedAt = Instant.now()
        symmetricKey = null
        return Base64.getEncoder().encodeToString(keyPair.public.encoded)
    }
}
