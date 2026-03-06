package io.rynbridge.translation

import io.rynbridge.core.BridgeValue

data class TranslateResult(
    val text: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "text" to BridgeValue.string(text)
    )
}

data class TranslateBatchResult(
    val results: List<String>
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "results" to BridgeValue.array(results.map { BridgeValue.string(it) })
    )
}

data class DetectLanguageResult(
    val language: String,
    val confidence: Double
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "language" to BridgeValue.string(language),
        "confidence" to BridgeValue.double(confidence)
    )
}

data class GetSupportedLanguagesResult(
    val languages: List<String>
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "languages" to BridgeValue.array(languages.map { BridgeValue.string(it) })
    )
}

data class DownloadModelResult(
    val success: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "success" to BridgeValue.bool(success)
    )
}

data class DeleteModelResult(
    val success: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "success" to BridgeValue.bool(success)
    )
}

data class GetDownloadedModelsResult(
    val models: List<String>
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "models" to BridgeValue.array(models.map { BridgeValue.string(it) })
    )
}

data class DownloadProgressEvent(
    val language: String,
    val progress: Double
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "language" to BridgeValue.string(language),
        "progress" to BridgeValue.double(progress)
    )
}

interface TranslationProvider {
    suspend fun translate(text: String, source: String, target: String): TranslateResult
    suspend fun translateBatch(texts: List<String>, source: String, target: String): TranslateBatchResult
    suspend fun detectLanguage(text: String): DetectLanguageResult
    suspend fun getSupportedLanguages(): GetSupportedLanguagesResult
    suspend fun downloadModel(language: String): DownloadModelResult
    suspend fun deleteModel(language: String): DeleteModelResult
    suspend fun getDownloadedModels(): GetDownloadedModelsResult
}
