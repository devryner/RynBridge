package com.devryner.rynbridge.translation

import com.devryner.rynbridge.core.*

class TranslationModule(provider: TranslationProvider) : BridgeModule {

    override val name = "translation"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "translate" to { payload ->
            val text = payload["text"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: text")
            val source = payload["source"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: source")
            val target = payload["target"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: target")
            val result = provider.translate(text, source, target)
            result.toPayload()
        },
        "translateBatch" to { payload ->
            val texts = payload["texts"]?.arrayValue
                ?.mapNotNull { it.stringValue }
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: texts")
            val source = payload["source"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: source")
            val target = payload["target"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: target")
            val result = provider.translateBatch(texts, source, target)
            result.toPayload()
        },
        "detectLanguage" to { payload ->
            val text = payload["text"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: text")
            val result = provider.detectLanguage(text)
            result.toPayload()
        },
        "getSupportedLanguages" to { _ ->
            val result = provider.getSupportedLanguages()
            result.toPayload()
        },
        "downloadModel" to { payload ->
            val language = payload["language"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: language")
            val result = provider.downloadModel(language)
            result.toPayload()
        },
        "deleteModel" to { payload ->
            val language = payload["language"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: language")
            val result = provider.deleteModel(language)
            result.toPayload()
        },
        "getDownloadedModels" to { _ ->
            val result = provider.getDownloadedModels()
            result.toPayload()
        }
    )
}
