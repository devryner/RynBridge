package com.devryner.rynbridge.crypto

import com.devryner.rynbridge.core.BridgeValue

data class EncryptResult(
    val ciphertext: String,
    val iv: String,
    val tag: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "ciphertext" to BridgeValue.string(ciphertext),
        "iv" to BridgeValue.string(iv),
        "tag" to BridgeValue.string(tag)
    )
}

data class CryptoStatus(
    val initialized: Boolean,
    val keyCreatedAt: String?,
    val algorithm: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "initialized" to BridgeValue.bool(initialized),
        "keyCreatedAt" to (keyCreatedAt?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "algorithm" to BridgeValue.string(algorithm)
    )
}

interface CryptoProvider {
    suspend fun generateKeyPair(): String
    suspend fun performKeyExchange(remotePublicKey: String): Boolean
    suspend fun encrypt(data: String, associatedData: String?): EncryptResult
    suspend fun decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?): String
    suspend fun getStatus(): CryptoStatus
    suspend fun rotateKeys(): String
}
