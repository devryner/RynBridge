package io.rynbridge.speech

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class SpeechModuleTest {

    @Test
    fun `startRecognition returns sessionId`() = runTest {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        val handler = module.actions["startRecognition"]!!

        val result = handler(mapOf("language" to BridgeValue.string("en-US")))
        assertEquals("session-1", result["sessionId"]?.stringValue)
        assertEquals("en-US", provider.lastLanguage)
    }

    @Test
    fun `stopRecognition returns transcript`() = runTest {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        val handler = module.actions["stopRecognition"]!!

        val result = handler(mapOf("sessionId" to BridgeValue.string("session-1")))
        assertEquals("Hello world", result["transcript"]?.stringValue)
    }

    @Test
    fun `speak with options`() = runTest {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        val handler = module.actions["speak"]!!

        val result = handler(mapOf(
            "text" to BridgeValue.string("Say this"),
            "language" to BridgeValue.string("en-US"),
            "rate" to BridgeValue.double(1.5),
            "pitch" to BridgeValue.double(1.0),
            "voiceId" to BridgeValue.string("voice-1")
        ))
        assertTrue(result.isEmpty())
        assertNotNull(provider.lastSpeakOptions)
        assertEquals("Say this", provider.lastSpeakOptions!!.text)
        assertEquals("en-US", provider.lastSpeakOptions!!.language)
        assertEquals(1.5, provider.lastSpeakOptions!!.rate)
        assertEquals(1.0, provider.lastSpeakOptions!!.pitch)
        assertEquals("voice-1", provider.lastSpeakOptions!!.voiceId)
    }

    @Test
    fun `stopSpeaking calls provider`() = runTest {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        val handler = module.actions["stopSpeaking"]!!

        val result = handler(emptyMap())
        assertTrue(result.isEmpty())
        assertTrue(provider.stopSpeakingCalled)
    }

    @Test
    fun `getVoices returns voice list`() = runTest {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        val handler = module.actions["getVoices"]!!

        val result = handler(emptyMap())
        val voices = result["voices"]?.arrayValue
        assertNotNull(voices)
        assertEquals(1, voices!!.size)
        assertEquals("voice-1", voices[0].dictionaryValue?.get("id")?.stringValue)
        assertEquals("Samantha", voices[0].dictionaryValue?.get("name")?.stringValue)
    }

    @Test
    fun `requestPermission returns granted`() = runTest {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        val handler = module.actions["requestPermission"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["granted"]?.boolValue)
    }

    @Test
    fun `getPermissionStatus returns status`() = runTest {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        val handler = module.actions["getPermissionStatus"]!!

        val result = handler(emptyMap())
        assertEquals("granted", result["status"]?.stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockSpeechProvider()
        val module = SpeechModule(provider)
        assertEquals("speech", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockSpeechProvider : SpeechProvider {
    var lastLanguage: String? = null
    var lastSpeakOptions: SpeakOptions? = null
    var stopSpeakingCalled = false

    override suspend fun startRecognition(language: String?): StartRecognitionResult {
        lastLanguage = language
        return StartRecognitionResult(sessionId = "session-1")
    }

    override suspend fun stopRecognition(sessionId: String): StopRecognitionResult =
        StopRecognitionResult(transcript = "Hello world")

    override suspend fun speak(options: SpeakOptions) {
        lastSpeakOptions = options
    }

    override fun stopSpeaking() {
        stopSpeakingCalled = true
    }

    override suspend fun getVoices(): GetVoicesResult =
        GetVoicesResult(voices = listOf(Voice(id = "voice-1", name = "Samantha", language = "en-US")))

    override suspend fun requestPermission(): PermissionResult =
        PermissionResult(granted = true)

    override suspend fun getPermissionStatus(): PermissionStatusResult =
        PermissionStatusResult(status = "granted")
}
