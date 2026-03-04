import Foundation
import RynBridge

public struct MediaModule: BridgeModule, Sendable {
    public let name = "media"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: MediaProvider) {
        actions = [
            "playAudio": { payload in
                guard let source = payload["source"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: source")
                }
                let loop = payload["loop"]?.boolValue ?? false
                let volume = payload["volume"]?.doubleValue ?? 1.0
                let playerId = try await provider.playAudio(source: source, loop: loop, volume: volume)
                return ["playerId": .string(playerId)]
            },
            "pauseAudio": { payload in
                guard let playerId = payload["playerId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: playerId")
                }
                try await provider.pauseAudio(playerId: playerId)
                return [:]
            },
            "stopAudio": { payload in
                guard let playerId = payload["playerId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: playerId")
                }
                try await provider.stopAudio(playerId: playerId)
                return [:]
            },
            "getAudioStatus": { payload in
                guard let playerId = payload["playerId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: playerId")
                }
                let status = try await provider.getAudioStatus(playerId: playerId)
                return status.toPayload()
            },
            "startRecording": { payload in
                let format = payload["format"]?.stringValue ?? "m4a"
                let quality = payload["quality"]?.stringValue ?? "medium"
                let recordingId = try await provider.startRecording(format: format, quality: quality)
                return ["recordingId": .string(recordingId)]
            },
            "stopRecording": { payload in
                guard let recordingId = payload["recordingId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: recordingId")
                }
                let result = try await provider.stopRecording(recordingId: recordingId)
                return result.toPayload()
            },
            "pickMedia": { payload in
                let type = payload["type"]?.stringValue ?? "any"
                let multiple = payload["multiple"]?.boolValue ?? false
                let files = try await provider.pickMedia(type: type, multiple: multiple)
                return ["files": .array(files.map { .object($0.toPayload()) })]
            },
        ]
    }
}
