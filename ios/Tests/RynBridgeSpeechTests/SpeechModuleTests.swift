import XCTest
@testable import RynBridge
@testable import RynBridgeSpeech

final class SpeechModuleTests: XCTestCase {
    func testStartRecognition() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["startRecognition"]!

        let result = try await handler(["language": .string("en-US")])
        XCTAssertEqual(result["sessionId"]?.stringValue, "session-123")
        XCTAssertEqual(provider.lastRecognitionLanguage, "en-US")
    }

    func testStartRecognitionWithoutLanguage() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["startRecognition"]!

        let result = try await handler([:])
        XCTAssertEqual(result["sessionId"]?.stringValue, "session-123")
        XCTAssertNil(provider.lastRecognitionLanguage)
    }

    func testStopRecognition() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["stopRecognition"]!

        let result = try await handler(["sessionId": .string("session-123")])
        XCTAssertEqual(result["transcript"]?.stringValue, "Hello world")
        XCTAssertEqual(provider.lastStoppedSessionId, "session-123")
    }

    func testSpeak() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["speak"]!

        let result = try await handler([
            "text": .string("Hello"),
            "language": .string("en-US"),
            "rate": .double(1.0),
            "pitch": .double(1.2),
            "voiceId": .string("voice-1"),
        ])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastSpeakOptions?.text, "Hello")
        XCTAssertEqual(provider.lastSpeakOptions?.language, "en-US")
        XCTAssertEqual(provider.lastSpeakOptions?.rate, 1.0)
        XCTAssertEqual(provider.lastSpeakOptions?.pitch, 1.2)
        XCTAssertEqual(provider.lastSpeakOptions?.voiceId, "voice-1")
    }

    func testStopSpeaking() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["stopSpeaking"]!

        let result = try await handler([:])
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(provider.stopSpeakingCalled)
    }

    func testGetVoices() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["getVoices"]!

        let result = try await handler([:])
        let voices = result["voices"]?.arrayValue
        XCTAssertNotNil(voices)
        XCTAssertEqual(voices?.count, 2)
        let first = voices?.first?.dictionaryValue
        XCTAssertEqual(first?["id"]?.stringValue, "voice-1")
        XCTAssertEqual(first?["name"]?.stringValue, "Samantha")
        XCTAssertEqual(first?["language"]?.stringValue, "en-US")
    }

    func testRequestPermission() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([:])
        XCTAssertEqual(result["granted"]?.boolValue, true)
    }

    func testGetPermissionStatus() async throws {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        let handler = module.actions["getPermissionStatus"]!

        let result = try await handler([:])
        XCTAssertEqual(result["status"]?.stringValue, "authorized")
    }

    func testModuleNameAndVersion() {
        let provider = MockSpeechProvider()
        let module = SpeechModule(provider: provider)
        XCTAssertEqual(module.name, "speech")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockSpeechProvider: SpeechProvider, @unchecked Sendable {
    var lastRecognitionLanguage: String?
    var lastStoppedSessionId: String?
    var lastSpeakOptions: SpeakOptions?
    var stopSpeakingCalled = false

    func startRecognition(language: String?) async throws -> StartRecognitionResult {
        lastRecognitionLanguage = language
        return StartRecognitionResult(sessionId: "session-123")
    }

    func stopRecognition(sessionId: String) async throws -> StopRecognitionResult {
        lastStoppedSessionId = sessionId
        return StopRecognitionResult(transcript: "Hello world")
    }

    func speak(options: SpeakOptions) async throws {
        lastSpeakOptions = options
    }

    func stopSpeaking() {
        stopSpeakingCalled = true
    }

    func getVoices() async throws -> GetVoicesResult {
        GetVoicesResult(voices: [
            Voice(id: "voice-1", name: "Samantha", language: "en-US"),
            Voice(id: "voice-2", name: "Daniel", language: "en-GB"),
        ])
    }

    func requestPermission() async throws -> PermissionResult {
        PermissionResult(granted: true)
    }

    func getPermissionStatus() async throws -> PermissionStatusResult {
        PermissionStatusResult(status: "authorized")
    }
}
