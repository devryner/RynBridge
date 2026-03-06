import Foundation
import RynBridge

public struct StartRecognitionResult: Sendable {
    public let sessionId: String

    public init(sessionId: String) {
        self.sessionId = sessionId
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "sessionId": .string(sessionId),
        ]
    }
}

public struct StopRecognitionResult: Sendable {
    public let transcript: String

    public init(transcript: String) {
        self.transcript = transcript
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "transcript": .string(transcript),
        ]
    }
}

public struct RecognitionResultEvent: Sendable {
    public let transcript: String
    public let isFinal: Bool

    public init(transcript: String, isFinal: Bool) {
        self.transcript = transcript
        self.isFinal = isFinal
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "transcript": .string(transcript),
            "isFinal": .bool(isFinal),
        ]
    }
}

public struct SpeakOptions: Sendable {
    public let text: String
    public let language: String?
    public let rate: Double?
    public let pitch: Double?
    public let voiceId: String?

    public init(text: String, language: String? = nil, rate: Double? = nil, pitch: Double? = nil, voiceId: String? = nil) {
        self.text = text
        self.language = language
        self.rate = rate
        self.pitch = pitch
        self.voiceId = voiceId
    }
}

public struct Voice: Sendable {
    public let id: String
    public let name: String
    public let language: String

    public init(id: String, name: String, language: String) {
        self.id = id
        self.name = name
        self.language = language
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "id": .string(id),
            "name": .string(name),
            "language": .string(language),
        ]
    }
}

public struct GetVoicesResult: Sendable {
    public let voices: [Voice]

    public init(voices: [Voice]) {
        self.voices = voices
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "voices": .array(voices.map { voice in
                .dictionary(voice.toPayload())
            }),
        ]
    }
}

public struct PermissionResult: Sendable {
    public let granted: Bool

    public init(granted: Bool) {
        self.granted = granted
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "granted": .bool(granted),
        ]
    }
}

public struct PermissionStatusResult: Sendable {
    public let status: String

    public init(status: String) {
        self.status = status
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "status": .string(status),
        ]
    }
}

public protocol SpeechProvider: Sendable {
    func startRecognition(language: String?) async throws -> StartRecognitionResult
    func stopRecognition(sessionId: String) async throws -> StopRecognitionResult
    func speak(options: SpeakOptions) async throws
    func stopSpeaking()
    func getVoices() async throws -> GetVoicesResult
    func requestPermission() async throws -> PermissionResult
    func getPermissionStatus() async throws -> PermissionStatusResult
}
