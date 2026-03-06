package io.rynbridge.playground.providers

import io.rynbridge.media.*
import java.util.UUID

class MockMediaProvider : MediaProvider {
    override suspend fun playAudio(source: String, loop: Boolean, volume: Double): String {
        return "player_${UUID.randomUUID().toString().take(8)}"
    }

    override suspend fun pauseAudio(playerId: String) {}

    override suspend fun stopAudio(playerId: String) {}

    override suspend fun getAudioStatus(playerId: String): AudioStatus {
        return AudioStatus(position = 30.0, duration = 180.0, isPlaying = true)
    }

    override suspend fun startRecording(format: String, quality: String): String {
        return "rec_${UUID.randomUUID().toString().take(8)}"
    }

    override suspend fun stopRecording(recordingId: String): RecordingResult {
        return RecordingResult(filePath = "/tmp/${recordingId}.m4a", duration = 5.2, size = 52400)
    }

    override suspend fun pickMedia(type: String, multiple: Boolean): List<MediaFile> {
        return listOf(
            MediaFile(name = "photo.jpg", path = "/tmp/photo.jpg", mimeType = "image/jpeg", size = 1024000)
        )
    }
}
