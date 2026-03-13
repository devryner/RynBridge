package io.rynbridge.media

import android.content.Context
import io.rynbridge.core.*

class MediaModule(provider: MediaProvider) : BridgeModule {
    constructor(context: Context) : this(DefaultMediaProvider(context))

    override val name = "media"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "playAudio" to { payload ->
            val source = payload["source"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: source")
            val loop = payload["loop"]?.boolValue ?: false
            val volume = payload["volume"]?.doubleValue ?: 1.0
            val playerId = provider.playAudio(source, loop, volume)
            mapOf("playerId" to BridgeValue.string(playerId))
        },
        "pauseAudio" to { payload ->
            val playerId = payload["playerId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: playerId")
            provider.pauseAudio(playerId)
            emptyMap()
        },
        "stopAudio" to { payload ->
            val playerId = payload["playerId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: playerId")
            provider.stopAudio(playerId)
            emptyMap()
        },
        "getAudioStatus" to { payload ->
            val playerId = payload["playerId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: playerId")
            val status = provider.getAudioStatus(playerId)
            status.toPayload()
        },
        "startRecording" to { payload ->
            val format = payload["format"]?.stringValue ?: "m4a"
            val quality = payload["quality"]?.stringValue ?: "medium"
            val recordingId = provider.startRecording(format, quality)
            mapOf("recordingId" to BridgeValue.string(recordingId))
        },
        "stopRecording" to { payload ->
            val recordingId = payload["recordingId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: recordingId")
            val result = provider.stopRecording(recordingId)
            result.toPayload()
        },
        "pickMedia" to { payload ->
            val type = payload["type"]?.stringValue ?: "any"
            val multiple = payload["multiple"]?.boolValue ?: false
            val files = provider.pickMedia(type, multiple)
            mapOf("files" to BridgeValue.array(files.map { BridgeValue.dict(it.toPayload()) }))
        }
    )
}
