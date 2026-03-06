#if os(iOS)
import Foundation
import AVFoundation
import Speech
import RynBridge

public final class DefaultSpeechProvider: SpeechProvider, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentSessionId: String?

    public init() {}

    public func startRecognition(language: String?) async throws -> StartRecognitionResult {
        let locale = language.map { Locale(identifier: $0) } ?? Locale.current
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw RynBridgeError(code: .unknown, message: "Speech recognizer is not available for locale: \(locale.identifier)")
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()

        let sessionId = UUID().uuidString

        recognitionTask = recognizer.recognitionTask(with: request) { _, _ in
            // Results are delivered via the bridge event system (onRecognitionResult)
        }

        self.audioEngine = engine
        self.recognitionRequest = request
        self.currentSessionId = sessionId

        return StartRecognitionResult(sessionId: sessionId)
    }

    public func stopRecognition(sessionId: String) async throws -> StopRecognitionResult {
        guard currentSessionId == sessionId else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid session ID: \(sessionId)")
        }

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        let transcript: String
        if let task = recognitionTask {
            task.cancel()
            transcript = ""
        } else {
            transcript = ""
        }

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        currentSessionId = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        return StopRecognitionResult(transcript: transcript)
    }

    public func speak(options: SpeakOptions) async throws {
        let utterance = AVSpeechUtterance(string: options.text)

        if let language = options.language {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }

        if let voiceId = options.voiceId {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
        }

        if let rate = options.rate {
            utterance.rate = Float(rate) * AVSpeechUtteranceDefaultSpeechRate
        }

        if let pitch = options.pitch {
            utterance.pitchMultiplier = Float(pitch)
        }

        synthesizer.speak(utterance)
    }

    public func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    public func getVoices() async throws -> GetVoicesResult {
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        let voices = availableVoices.map { voice in
            Voice(
                id: voice.identifier,
                name: voice.name,
                language: voice.language
            )
        }
        return GetVoicesResult(voices: voices)
    }

    public func requestPermission() async throws -> PermissionResult {
        let granted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        return PermissionResult(granted: granted)
    }

    public func getPermissionStatus() async throws -> PermissionStatusResult {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        let status: String
        switch authStatus {
        case .authorized:
            status = "granted"
        case .denied:
            status = "denied"
        case .restricted:
            status = "restricted"
        case .notDetermined:
            status = "not_determined"
        @unknown default:
            status = "unknown"
        }
        return PermissionStatusResult(status: status)
    }
}
#endif
