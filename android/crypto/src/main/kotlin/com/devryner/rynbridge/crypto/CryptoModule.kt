package com.devryner.rynbridge.crypto

import com.devryner.rynbridge.core.*

class CryptoModule(provider: CryptoProvider) : BridgeModule {
    constructor() : this(DefaultCryptoProvider())

    override val name = "crypto"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "generateKeyPair" to { _ ->
            val publicKey = provider.generateKeyPair()
            mapOf("publicKey" to BridgeValue.string(publicKey))
        },
        "performKeyExchange" to { payload ->
            val remotePublicKey = payload["remotePublicKey"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: remotePublicKey")
            val established = provider.performKeyExchange(remotePublicKey)
            mapOf("sessionEstablished" to BridgeValue.bool(established))
        },
        "encrypt" to { payload ->
            val data = payload["data"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: data")
            val associatedData = payload["associatedData"]?.stringValue
            val result = provider.encrypt(data, associatedData)
            result.toPayload()
        },
        "decrypt" to { payload ->
            val ciphertext = payload["ciphertext"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: ciphertext")
            val iv = payload["iv"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: iv")
            val tag = payload["tag"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: tag")
            val associatedData = payload["associatedData"]?.stringValue
            val plaintext = provider.decrypt(ciphertext, iv, tag, associatedData)
            mapOf("plaintext" to BridgeValue.string(plaintext))
        },
        "getStatus" to { _ ->
            val status = provider.getStatus()
            status.toPayload()
        },
        "rotateKeys" to { _ ->
            val publicKey = provider.rotateKeys()
            mapOf("publicKey" to BridgeValue.string(publicKey))
        }
    )
}
