package io.rynbridge.speech

import android.content.Context
import io.rynbridge.core.*

class SpeechModule(provider: SpeechProvider) : BridgeModule {
    constructor(context: Context) : this(DefaultSpeechProvider(context))

    override val name = "speech"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "startRecognition" to { payload ->
            val language = payload["language"]?.stringValue
            val result = provider.startRecognition(language)
            result.toPayload()
        },
        "stopRecognition" to { payload ->
            val sessionId = payload["sessionId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: sessionId")
            val result = provider.stopRecognition(sessionId)
            result.toPayload()
        },
        "speak" to { payload ->
            val text = payload["text"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: text")
            val language = payload["language"]?.stringValue
            val rate = payload["rate"]?.doubleValue
            val pitch = payload["pitch"]?.doubleValue
            val voiceId = payload["voiceId"]?.stringValue
            val options = SpeakOptions(text = text, language = language, rate = rate, pitch = pitch, voiceId = voiceId)
            provider.speak(options)
            emptyMap()
        },
        "stopSpeaking" to { _ ->
            provider.stopSpeaking()
            emptyMap()
        },
        "getVoices" to { _ ->
            val result = provider.getVoices()
            result.toPayload()
        },
        "requestPermission" to { _ ->
            val result = provider.requestPermission()
            result.toPayload()
        },
        "getPermissionStatus" to { _ ->
            val result = provider.getPermissionStatus()
            result.toPayload()
        }
    )
}
