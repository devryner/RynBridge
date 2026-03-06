package io.rynbridge.speech

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import io.rynbridge.core.RynBridgeError
import io.rynbridge.core.ErrorCode
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.Locale
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class DefaultSpeechProvider(
    private val context: Context
) : SpeechProvider {

    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsInitialized = false
    private var currentSessionId: String? = null

    override suspend fun startRecognition(language: String?): StartRecognitionResult {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Speech recognition is not available on this device")
        }

        val sessionId = UUID.randomUUID().toString()
        val recognizer = SpeechRecognizer.createSpeechRecognizer(context)

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            if (language != null) {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            }
        }

        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onError(error: Int) {}
            override fun onResults(results: Bundle?) {
                // Final results are delivered via the bridge event system (onRecognitionResult)
            }
            override fun onPartialResults(partialResults: Bundle?) {
                // Partial results are delivered via the bridge event system (onRecognitionResult)
            }
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        recognizer.startListening(intent)

        speechRecognizer = recognizer
        currentSessionId = sessionId

        return StartRecognitionResult(sessionId = sessionId)
    }

    override suspend fun stopRecognition(sessionId: String): StopRecognitionResult {
        if (currentSessionId != sessionId) {
            throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Invalid session ID: $sessionId")
        }

        speechRecognizer?.stopListening()
        speechRecognizer?.destroy()
        speechRecognizer = null
        currentSessionId = null

        return StopRecognitionResult(transcript = "")
    }

    override suspend fun speak(options: SpeakOptions) {
        val tts = getOrInitTts()

        if (options.rate != null) {
            tts.setSpeechRate(options.rate.toFloat())
        }

        if (options.pitch != null) {
            tts.setPitch(options.pitch.toFloat())
        }

        if (options.language != null) {
            tts.language = Locale.forLanguageTag(options.language)
        }

        if (options.voiceId != null) {
            val voice = tts.voices?.firstOrNull { it.name == options.voiceId }
            if (voice != null) {
                tts.voice = voice
            }
        }

        suspendCancellableCoroutine { continuation ->
            val utteranceId = UUID.randomUUID().toString()
            tts.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
                override fun onStart(id: String?) {}
                override fun onDone(id: String?) {
                    if (id == utteranceId) {
                        continuation.resume(Unit)
                    }
                }
                @Deprecated("Deprecated in Java")
                override fun onError(id: String?) {
                    if (id == utteranceId) {
                        continuation.resumeWithException(
                            RynBridgeError(code = ErrorCode.UNKNOWN, message = "TTS error for utterance: $id")
                        )
                    }
                }
            })

            tts.speak(options.text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
        }
    }

    override fun stopSpeaking() {
        textToSpeech?.stop()
    }

    override suspend fun getVoices(): GetVoicesResult {
        val tts = getOrInitTts()
        val voices = tts.voices?.map { voice ->
            Voice(
                id = voice.name,
                name = voice.name,
                language = voice.locale.toLanguageTag()
            )
        } ?: emptyList()
        return GetVoicesResult(voices = voices)
    }

    override suspend fun requestPermission(): PermissionResult {
        val granted = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        return PermissionResult(granted = granted)
    }

    override suspend fun getPermissionStatus(): PermissionStatusResult {
        val status = when (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO)) {
            PackageManager.PERMISSION_GRANTED -> "granted"
            PackageManager.PERMISSION_DENIED -> "denied"
            else -> "not_determined"
        }
        return PermissionStatusResult(status = status)
    }

    private suspend fun getOrInitTts(): TextToSpeech {
        textToSpeech?.let { if (ttsInitialized) return it }

        return suspendCancellableCoroutine { continuation ->
            val tts = TextToSpeech(context) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    ttsInitialized = true
                    continuation.resume(textToSpeech!!)
                } else {
                    continuation.resumeWithException(
                        RynBridgeError(code = ErrorCode.UNKNOWN, message = "Failed to initialize TextToSpeech")
                    )
                }
            }
            textToSpeech = tts
        }
    }
}
