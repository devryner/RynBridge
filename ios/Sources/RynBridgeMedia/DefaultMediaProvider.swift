import Foundation
import RynBridge

#if canImport(AVFoundation) && canImport(UIKit)
import AVFoundation
import UIKit
import UniformTypeIdentifiers
import PhotosUI

public final class DefaultMediaProvider: MediaProvider, @unchecked Sendable {
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioRecorders: [String: AVAudioRecorder] = [:]
    private var recordingStartTimes: [String: Date] = [:]
    private let queue = DispatchQueue(label: "io.rynbridge.media")

    public init() {}

    public func playAudio(source: String, loop: Bool, volume: Double) async throws -> String {
        let playerId = UUID().uuidString

        let data: Data
        if source.hasPrefix("http://") || source.hasPrefix("https://") {
            guard let url = URL(string: source) else {
                throw RynBridgeError(code: .invalidMessage, message: "Invalid audio URL: \(source)")
            }
            let (downloaded, _) = try await URLSession.shared.data(from: url)
            data = downloaded
        } else if source.hasPrefix("file://") || source.hasPrefix("/") {
            let fileURL = source.hasPrefix("file://") ? URL(string: source)! : URL(fileURLWithPath: source)
            data = try Data(contentsOf: fileURL)
        } else if let bundleURL = Bundle.main.url(forResource: source, withExtension: nil) {
            data = try Data(contentsOf: bundleURL)
        } else {
            throw RynBridgeError(code: .invalidMessage, message: "Cannot resolve audio source: \(source)")
        }

        let player = try AVAudioPlayer(data: data)
        player.volume = Float(volume)
        player.numberOfLoops = loop ? -1 : 0
        player.prepareToPlay()
        player.play()

        queue.sync { audioPlayers[playerId] = player }
        return playerId
    }

    public func pauseAudio(playerId: String) async throws {
        guard let player = queue.sync(execute: { audioPlayers[playerId] }) else {
            throw RynBridgeError(code: .unknown, message: "Player not found: \(playerId)")
        }
        player.pause()
    }

    public func stopAudio(playerId: String) async throws {
        guard let player = queue.sync(execute: { audioPlayers.removeValue(forKey: playerId) }) else {
            throw RynBridgeError(code: .unknown, message: "Player not found: \(playerId)")
        }
        player.stop()
    }

    public func getAudioStatus(playerId: String) async throws -> AudioStatus {
        guard let player = queue.sync(execute: { audioPlayers[playerId] }) else {
            throw RynBridgeError(code: .unknown, message: "Player not found: \(playerId)")
        }
        return AudioStatus(
            position: player.currentTime,
            duration: player.duration,
            isPlaying: player.isPlaying
        )
    }

    public func startRecording(format: String, quality: String) async throws -> String {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        let recordingId = UUID().uuidString
        let directory = FileManager.default.temporaryDirectory
        let ext = format == "wav" ? "wav" : "m4a"
        let fileURL = directory.appendingPathComponent("\(recordingId).\(ext)")

        var settings: [String: Any] = [
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
        ]

        if ext == "wav" {
            settings[AVFormatIDKey] = Int(kAudioFormatLinearPCM)
            settings[AVLinearPCMBitDepthKey] = 16
        } else {
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC)
            let qualityValue: AVAudioQuality = quality == "high" ? .max : quality == "low" ? .min : .medium
            settings[AVEncoderAudioQualityKey] = qualityValue.rawValue
        }

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.record()

        queue.sync {
            audioRecorders[recordingId] = recorder
            recordingStartTimes[recordingId] = Date()
        }
        return recordingId
    }

    public func stopRecording(recordingId: String) async throws -> RecordingResult {
        let (recorder, _) = queue.sync { () -> (AVAudioRecorder?, Date?) in
            let r = audioRecorders.removeValue(forKey: recordingId)
            let t = recordingStartTimes.removeValue(forKey: recordingId)
            return (r, t)
        }

        guard let recorder else {
            throw RynBridgeError(code: .unknown, message: "Recorder not found: \(recordingId)")
        }

        let duration = recorder.currentTime
        recorder.stop()

        let filePath = recorder.url.path
        let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
        let size = (attrs[.size] as? Int) ?? 0

        return RecordingResult(filePath: filePath, duration: duration, size: size)
    }

    public func pickMedia(type: String, multiple: Bool) async throws -> [MediaFile] {
        throw RynBridgeError(code: .unknown, message: "pickMedia requires a UIViewController context. Use a custom provider for UI-based media picking.")
    }
}
#endif
