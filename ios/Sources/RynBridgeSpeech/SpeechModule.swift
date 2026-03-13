import Foundation
import RynBridge

public struct SpeechModule: BridgeModule, Sendable {
    public let name = "speech"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init() {
        self.init(provider: DefaultSpeechProvider())
    }

    public init(provider: SpeechProvider) {
        actions = [
            "startRecognition": { payload in
                let language = payload["language"]?.stringValue
                let result = try await provider.startRecognition(language: language)
                return result.toPayload()
            },
            "stopRecognition": { payload in
                guard let sessionId = payload["sessionId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: sessionId")
                }
                let result = try await provider.stopRecognition(sessionId: sessionId)
                return result.toPayload()
            },
            "speak": { payload in
                guard let text = payload["text"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: text")
                }
                let language = payload["language"]?.stringValue
                let rate = payload["rate"]?.doubleValue
                let pitch = payload["pitch"]?.doubleValue
                let voiceId = payload["voiceId"]?.stringValue
                let options = SpeakOptions(text: text, language: language, rate: rate, pitch: pitch, voiceId: voiceId)
                try await provider.speak(options: options)
                return [:]
            },
            "stopSpeaking": { _ in
                provider.stopSpeaking()
                return [:]
            },
            "getVoices": { _ in
                let result = try await provider.getVoices()
                return result.toPayload()
            },
            "requestPermission": { _ in
                let result = try await provider.requestPermission()
                return result.toPayload()
            },
            "getPermissionStatus": { _ in
                let result = try await provider.getPermissionStatus()
                return result.toPayload()
            },
        ]
    }
}
