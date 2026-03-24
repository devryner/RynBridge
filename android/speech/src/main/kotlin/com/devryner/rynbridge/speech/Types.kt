package com.devryner.rynbridge.speech

import com.devryner.rynbridge.core.BridgeValue

data class StartRecognitionResult(
    val sessionId: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "sessionId" to BridgeValue.string(sessionId)
    )
}

data class StopRecognitionResult(
    val transcript: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "transcript" to BridgeValue.string(transcript)
    )
}

data class RecognitionResultEvent(
    val transcript: String,
    val isFinal: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "transcript" to BridgeValue.string(transcript),
        "isFinal" to BridgeValue.bool(isFinal)
    )
}

data class SpeakOptions(
    val text: String,
    val language: String?,
    val rate: Double?,
    val pitch: Double?,
    val voiceId: String?
)

data class Voice(
    val id: String,
    val name: String,
    val language: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id),
        "name" to BridgeValue.string(name),
        "language" to BridgeValue.string(language)
    )
}

data class GetVoicesResult(
    val voices: List<Voice>
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "voices" to BridgeValue.array(voices.map { voice ->
            BridgeValue.dict(voice.toPayload())
        })
    )
}

data class PermissionResult(
    val granted: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "granted" to BridgeValue.bool(granted)
    )
}

data class PermissionStatusResult(
    val status: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "status" to BridgeValue.string(status)
    )
}

interface SpeechProvider {
    suspend fun startRecognition(language: String?): StartRecognitionResult
    suspend fun stopRecognition(sessionId: String): StopRecognitionResult
    suspend fun speak(options: SpeakOptions)
    fun stopSpeaking()
    suspend fun getVoices(): GetVoicesResult
    suspend fun requestPermission(): PermissionResult
    suspend fun getPermissionStatus(): PermissionStatusResult
}
