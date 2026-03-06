package io.rynbridge.media

import io.rynbridge.core.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class MediaModuleTest {

    @Test
    fun `playAudio returns player id`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["playAudio"]!!

        val result = handler(mapOf(
            "source" to BridgeValue.string("https://example.com/audio.mp3"),
            "loop" to BridgeValue.bool(true),
            "volume" to BridgeValue.double(0.8)
        ))
        assertEquals("player-001", result["playerId"]?.stringValue)
        assertEquals("https://example.com/audio.mp3", provider.lastPlaySource)
        assertEquals(true, provider.lastPlayLoop)
        assertEquals(0.8, provider.lastPlayVolume)
    }

    @Test
    fun `playAudio with defaults`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["playAudio"]!!

        handler(mapOf("source" to BridgeValue.string("audio.mp3")))
        assertEquals(false, provider.lastPlayLoop)
        assertEquals(1.0, provider.lastPlayVolume)
    }

    @Test
    fun `playAudio missing source throws`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["playAudio"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `pauseAudio returns empty`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["pauseAudio"]!!

        val result = handler(mapOf("playerId" to BridgeValue.string("player-001")))
        assertTrue(result.isEmpty())
        assertEquals("player-001", provider.lastPausedPlayerId)
    }

    @Test
    fun `pauseAudio missing playerId throws`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["pauseAudio"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `stopAudio returns empty`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["stopAudio"]!!

        val result = handler(mapOf("playerId" to BridgeValue.string("player-001")))
        assertTrue(result.isEmpty())
        assertEquals("player-001", provider.lastStoppedPlayerId)
    }

    @Test
    fun `getAudioStatus returns status`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["getAudioStatus"]!!

        val result = handler(mapOf("playerId" to BridgeValue.string("player-001")))
        assertEquals(30.5, result["position"]?.doubleValue)
        assertEquals(180.0, result["duration"]?.doubleValue)
        assertEquals(true, result["isPlaying"]?.boolValue)
    }

    @Test
    fun `startRecording returns recording id`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["startRecording"]!!

        val result = handler(mapOf(
            "format" to BridgeValue.string("wav"),
            "quality" to BridgeValue.string("high")
        ))
        assertEquals("rec-001", result["recordingId"]?.stringValue)
        assertEquals("wav", provider.lastRecordingFormat)
        assertEquals("high", provider.lastRecordingQuality)
    }

    @Test
    fun `startRecording with defaults`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["startRecording"]!!

        handler(emptyMap())
        assertEquals("m4a", provider.lastRecordingFormat)
        assertEquals("medium", provider.lastRecordingQuality)
    }

    @Test
    fun `stopRecording returns recording result`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["stopRecording"]!!

        val result = handler(mapOf("recordingId" to BridgeValue.string("rec-001")))
        assertEquals("/tmp/recording.m4a", result["filePath"]?.stringValue)
        assertEquals(45.2, result["duration"]?.doubleValue)
        assertEquals(1024L, result["size"]?.intValue)
    }

    @Test
    fun `stopRecording missing recordingId throws`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["stopRecording"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `pickMedia returns media files`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["pickMedia"]!!

        val result = handler(mapOf(
            "type" to BridgeValue.string("image"),
            "multiple" to BridgeValue.bool(true)
        ))
        val files = result["files"]?.arrayValue
        assertNotNull(files)
        assertEquals(1, files?.size)
        assertEquals("photo.jpg", files?.get(0)?.dictionaryValue?.get("name")?.stringValue)
        assertEquals("/tmp/photo.jpg", files?.get(0)?.dictionaryValue?.get("path")?.stringValue)
        assertEquals("image/jpeg", files?.get(0)?.dictionaryValue?.get("mimeType")?.stringValue)
        assertEquals(2048L, files?.get(0)?.dictionaryValue?.get("size")?.intValue)
    }

    @Test
    fun `pickMedia with defaults`() = runTest {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        val handler = module.actions["pickMedia"]!!

        handler(emptyMap())
        assertEquals("any", provider.lastPickType)
        assertEquals(false, provider.lastPickMultiple)
    }

    @Test
    fun `module name and version`() {
        val provider = MockMediaProvider()
        val module = MediaModule(provider)
        assertEquals("media", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockMediaProvider()
        bridge.register(MediaModule(provider))

        val requestJSON = """{"id":"req-1","module":"media","action":"startRecording","payload":{},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        withContext(Dispatchers.Default) { delay(200) }

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertEquals("rec-001", response.payload["recordingId"]?.stringValue)

        bridge.dispose()
    }
}

private class MockMediaProvider : MediaProvider {
    var lastPlaySource: String? = null
    var lastPlayLoop: Boolean? = null
    var lastPlayVolume: Double? = null
    var lastPausedPlayerId: String? = null
    var lastStoppedPlayerId: String? = null
    var lastRecordingFormat: String? = null
    var lastRecordingQuality: String? = null
    var lastPickType: String? = null
    var lastPickMultiple: Boolean? = null

    override suspend fun playAudio(source: String, loop: Boolean, volume: Double): String {
        lastPlaySource = source
        lastPlayLoop = loop
        lastPlayVolume = volume
        return "player-001"
    }

    override suspend fun pauseAudio(playerId: String) {
        lastPausedPlayerId = playerId
    }

    override suspend fun stopAudio(playerId: String) {
        lastStoppedPlayerId = playerId
    }

    override suspend fun getAudioStatus(playerId: String): AudioStatus {
        return AudioStatus(position = 30.5, duration = 180.0, isPlaying = true)
    }

    override suspend fun startRecording(format: String, quality: String): String {
        lastRecordingFormat = format
        lastRecordingQuality = quality
        return "rec-001"
    }

    override suspend fun stopRecording(recordingId: String): RecordingResult {
        return RecordingResult(filePath = "/tmp/recording.m4a", duration = 45.2, size = 1024)
    }

    override suspend fun pickMedia(type: String, multiple: Boolean): List<MediaFile> {
        lastPickType = type
        lastPickMultiple = multiple
        return listOf(
            MediaFile(name = "photo.jpg", path = "/tmp/photo.jpg", mimeType = "image/jpeg", size = 2048)
        )
    }
}
