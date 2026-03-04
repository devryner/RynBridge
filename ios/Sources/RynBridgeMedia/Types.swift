import Foundation
import RynBridge

public struct AudioStatus: Sendable {
    public let position: Double
    public let duration: Double
    public let isPlaying: Bool

    public init(position: Double, duration: Double, isPlaying: Bool) {
        self.position = position
        self.duration = duration
        self.isPlaying = isPlaying
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "position": .double(position),
            "duration": .double(duration),
            "isPlaying": .bool(isPlaying),
        ]
    }
}

public struct RecordingResult: Sendable {
    public let filePath: String
    public let duration: Double
    public let size: Int

    public init(filePath: String, duration: Double, size: Int) {
        self.filePath = filePath
        self.duration = duration
        self.size = size
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "filePath": .string(filePath),
            "duration": .double(duration),
            "size": .int(size),
        ]
    }
}

public struct MediaFile: Sendable {
    public let name: String
    public let path: String
    public let mimeType: String
    public let size: Int

    public init(name: String, path: String, mimeType: String, size: Int) {
        self.name = name
        self.path = path
        self.mimeType = mimeType
        self.size = size
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "name": .string(name),
            "path": .string(path),
            "mimeType": .string(mimeType),
            "size": .int(size),
        ]
    }
}

public protocol MediaProvider: Sendable {
    func playAudio(source: String, loop: Bool, volume: Double) async throws -> String
    func pauseAudio(playerId: String) async throws
    func stopAudio(playerId: String) async throws
    func getAudioStatus(playerId: String) async throws -> AudioStatus
    func startRecording(format: String, quality: String) async throws -> String
    func stopRecording(recordingId: String) async throws -> RecordingResult
    func pickMedia(type: String, multiple: Bool) async throws -> [MediaFile]
}
