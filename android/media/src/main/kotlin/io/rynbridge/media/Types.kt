package io.rynbridge.media

import io.rynbridge.core.BridgeValue

data class AudioStatus(
    val position: Double,
    val duration: Double,
    val isPlaying: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "position" to BridgeValue.double(position),
        "duration" to BridgeValue.double(duration),
        "isPlaying" to BridgeValue.bool(isPlaying)
    )
}

data class RecordingResult(
    val filePath: String,
    val duration: Double,
    val size: Int
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "filePath" to BridgeValue.string(filePath),
        "duration" to BridgeValue.double(duration),
        "size" to BridgeValue.int(size)
    )
}

data class MediaFile(
    val name: String,
    val path: String,
    val mimeType: String,
    val size: Int
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "name" to BridgeValue.string(name),
        "path" to BridgeValue.string(path),
        "mimeType" to BridgeValue.string(mimeType),
        "size" to BridgeValue.int(size)
    )
}

interface MediaProvider {
    suspend fun playAudio(source: String, loop: Boolean, volume: Double): String
    suspend fun pauseAudio(playerId: String)
    suspend fun stopAudio(playerId: String)
    suspend fun getAudioStatus(playerId: String): AudioStatus
    suspend fun startRecording(format: String, quality: String): String
    suspend fun stopRecording(recordingId: String): RecordingResult
    suspend fun pickMedia(type: String, multiple: Boolean): List<MediaFile>
}
