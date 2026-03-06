import XCTest
@testable import RynBridge
@testable import RynBridgeMedia

final class MediaModuleTests: XCTestCase {
    func testPlayAudio() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["playAudio"]!

        let result = try await handler([
            "source": .string("https://example.com/song.mp3"),
            "loop": .bool(true),
            "volume": .double(0.8),
        ])
        XCTAssertEqual(result["playerId"]?.stringValue, "player-001")
        XCTAssertEqual(provider.lastPlaySource, "https://example.com/song.mp3")
        XCTAssertEqual(provider.lastPlayLoop, true)
        XCTAssertEqual(provider.lastPlayVolume, 0.8)
    }

    func testPlayAudioDefaults() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["playAudio"]!

        _ = try await handler(["source": .string("audio.mp3")])
        XCTAssertEqual(provider.lastPlayLoop, false)
        XCTAssertEqual(provider.lastPlayVolume, 1.0)
    }

    func testPauseAudio() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["pauseAudio"]!

        let result = try await handler(["playerId": .string("player-001")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastPausedPlayerId, "player-001")
    }

    func testStopAudio() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["stopAudio"]!

        let result = try await handler(["playerId": .string("player-001")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastStoppedPlayerId, "player-001")
    }

    func testGetAudioStatus() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["getAudioStatus"]!

        let result = try await handler(["playerId": .string("player-001")])
        XCTAssertEqual(result["position"]?.doubleValue, 30.5)
        XCTAssertEqual(result["duration"]?.doubleValue, 180.0)
        XCTAssertEqual(result["isPlaying"]?.boolValue, true)
    }

    func testStartRecording() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["startRecording"]!

        let result = try await handler([
            "format": .string("wav"),
            "quality": .string("high"),
        ])
        XCTAssertEqual(result["recordingId"]?.stringValue, "rec-001")
        XCTAssertEqual(provider.lastRecordingFormat, "wav")
        XCTAssertEqual(provider.lastRecordingQuality, "high")
    }

    func testStartRecordingDefaults() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["startRecording"]!

        _ = try await handler([:])
        XCTAssertEqual(provider.lastRecordingFormat, "m4a")
        XCTAssertEqual(provider.lastRecordingQuality, "medium")
    }

    func testStopRecording() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["stopRecording"]!

        let result = try await handler(["recordingId": .string("rec-001")])
        XCTAssertEqual(result["filePath"]?.stringValue, "/tmp/recording-001.m4a")
        XCTAssertEqual(result["duration"]?.doubleValue, 45.2)
        XCTAssertEqual(result["size"]?.intValue, 1024000)
    }

    func testPickMedia() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["pickMedia"]!

        let result = try await handler([
            "type": .string("image"),
            "multiple": .bool(true),
        ])
        let files = result["files"]?.arrayValue
        XCTAssertNotNil(files)
        XCTAssertEqual(files?.count, 2)
        XCTAssertEqual(files?[0].dictionaryValue?["name"]?.stringValue, "photo1.jpg")
        XCTAssertEqual(files?[0].dictionaryValue?["mimeType"]?.stringValue, "image/jpeg")
        XCTAssertEqual(files?[1].dictionaryValue?["name"]?.stringValue, "photo2.png")
    }

    func testPickMediaDefaults() async throws {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        let handler = module.actions["pickMedia"]!

        _ = try await handler([:])
        XCTAssertEqual(provider.lastPickType, "any")
        XCTAssertEqual(provider.lastPickMultiple, false)
    }

    func testModuleNameAndVersion() {
        let provider = MockMediaProvider()
        let module = MediaModule(provider: provider)
        XCTAssertEqual(module.name, "media")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockMediaProvider()
        bridge.register(MediaModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"media","action":"getAudioStatus","payload":{"playerId":"player-001"},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["isPlaying"]?.boolValue, true)

        bridge.dispose()
    }
}

private final class MockMediaProvider: MediaProvider, @unchecked Sendable {
    var lastPlaySource: String?
    var lastPlayLoop: Bool?
    var lastPlayVolume: Double?
    var lastPausedPlayerId: String?
    var lastStoppedPlayerId: String?
    var lastRecordingFormat: String?
    var lastRecordingQuality: String?
    var lastPickType: String?
    var lastPickMultiple: Bool?

    func playAudio(source: String, loop: Bool, volume: Double) async throws -> String {
        lastPlaySource = source
        lastPlayLoop = loop
        lastPlayVolume = volume
        return "player-001"
    }

    func pauseAudio(playerId: String) async throws {
        lastPausedPlayerId = playerId
    }

    func stopAudio(playerId: String) async throws {
        lastStoppedPlayerId = playerId
    }

    func getAudioStatus(playerId: String) async throws -> AudioStatus {
        AudioStatus(position: 30.5, duration: 180.0, isPlaying: true)
    }

    func startRecording(format: String, quality: String) async throws -> String {
        lastRecordingFormat = format
        lastRecordingQuality = quality
        return "rec-001"
    }

    func stopRecording(recordingId: String) async throws -> RecordingResult {
        RecordingResult(filePath: "/tmp/recording-001.m4a", duration: 45.2, size: 1024000)
    }

    func pickMedia(type: String, multiple: Bool) async throws -> [MediaFile] {
        lastPickType = type
        lastPickMultiple = multiple
        return [
            MediaFile(name: "photo1.jpg", path: "/tmp/photo1.jpg", mimeType: "image/jpeg", size: 2048000),
            MediaFile(name: "photo2.png", path: "/tmp/photo2.png", mimeType: "image/png", size: 3072000),
        ]
    }
}
