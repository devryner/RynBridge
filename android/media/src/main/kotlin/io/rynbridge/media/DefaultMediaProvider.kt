package io.rynbridge.media

import android.content.Context
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import java.io.File
import io.rynbridge.core.ErrorCode
import io.rynbridge.core.RynBridgeError
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

class DefaultMediaProvider(private val context: Context) : MediaProvider {

    private val players = ConcurrentHashMap<String, MediaPlayer>()
    private val recorders = ConcurrentHashMap<String, MediaRecorder>()
    private val recordingFiles = ConcurrentHashMap<String, File>()
    private val recordingStartTimes = ConcurrentHashMap<String, Long>()

    override suspend fun playAudio(source: String, loop: Boolean, volume: Double): String {
        val playerId = UUID.randomUUID().toString()
        val player = MediaPlayer()

        player.setDataSource(source)
        player.isLooping = loop
        player.setVolume(volume.toFloat(), volume.toFloat())
        player.prepare()
        player.start()

        players[playerId] = player
        return playerId
    }

    override suspend fun pauseAudio(playerId: String) {
        val player = players[playerId]
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Player not found: $playerId")
        player.pause()
    }

    override suspend fun stopAudio(playerId: String) {
        val player = players.remove(playerId)
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Player not found: $playerId")
        player.stop()
        player.release()
    }

    override suspend fun getAudioStatus(playerId: String): AudioStatus {
        val player = players[playerId]
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Player not found: $playerId")
        return AudioStatus(
            position = player.currentPosition.toDouble() / 1000.0,
            duration = player.duration.toDouble() / 1000.0,
            isPlaying = player.isPlaying
        )
    }

    override suspend fun startRecording(format: String, quality: String): String {
        val recordingId = UUID.randomUUID().toString()
        val ext = if (format == "wav") "wav" else "m4a"
        val file = File(context.cacheDir, "$recordingId.$ext")

        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        recorder.setAudioSource(MediaRecorder.AudioSource.MIC)

        if (ext == "wav") {
            recorder.setOutputFormat(MediaRecorder.OutputFormat.DEFAULT)
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.DEFAULT)
        } else {
            recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            val bitRate = when (quality) {
                "high" -> 256000
                "low" -> 64000
                else -> 128000
            }
            recorder.setAudioEncodingBitRate(bitRate)
        }

        recorder.setAudioSamplingRate(44100)
        recorder.setOutputFile(file.absolutePath)
        recorder.prepare()
        recorder.start()

        recorders[recordingId] = recorder
        recordingFiles[recordingId] = file
        recordingStartTimes[recordingId] = System.currentTimeMillis()
        return recordingId
    }

    override suspend fun stopRecording(recordingId: String): RecordingResult {
        val recorder = recorders.remove(recordingId)
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Recorder not found: $recordingId")
        val file = recordingFiles.remove(recordingId)!!
        val startTime = recordingStartTimes.remove(recordingId)!!

        recorder.stop()
        recorder.release()

        val duration = (System.currentTimeMillis() - startTime).toDouble() / 1000.0
        val size = file.length().toInt()

        return RecordingResult(
            filePath = file.absolutePath,
            duration = duration,
            size = size
        )
    }

    override suspend fun pickMedia(type: String, multiple: Boolean): List<MediaFile> {
        throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "pickMedia requires an Activity context. Use a custom provider for UI-based media picking.")
    }
}
