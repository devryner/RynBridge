#if canImport(AVFoundation) && canImport(UIKit)
import Foundation
import AVFoundation
import UIKit
import UniformTypeIdentifiers
import PhotosUI
import RynBridge

public final class DefaultMediaProvider: NSObject, MediaProvider, PHPickerViewControllerDelegate, @unchecked Sendable {
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioRecorders: [String: AVAudioRecorder] = [:]
    private var recordingStartTimes: [String: Date] = [:]
    private let queue = DispatchQueue(label: "io.rynbridge.media")
    private var pickContinuation: CheckedContinuation<[MediaFile], any Error>?

    public override init() {
        super.init()
    }

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

        switch session.recordPermission {
        case .denied:
            throw RynBridgeError(code: .unknown, message: "Microphone permission denied")
        case .undetermined:
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                session.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
            if !granted {
                throw RynBridgeError(code: .unknown, message: "Microphone permission denied")
            }
        default:
            break
        }

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
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let viewController = Self.topViewController() else {
                    continuation.resume(returning: [])
                    return
                }
                self.pickContinuation = continuation

                var config = PHPickerConfiguration()
                config.selectionLimit = multiple ? 0 : 1
                switch type {
                case "image":
                    config.filter = .images
                case "video":
                    config.filter = .videos
                default:
                    config.filter = .any(of: [.images, .videos])
                }

                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                viewController.present(picker, animated: true)
            }
        }
    }

    // MARK: - PHPickerViewControllerDelegate

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            pickContinuation?.resume(returning: [])
            pickContinuation = nil
            return
        }

        Task {
            var files: [MediaFile] = []
            for result in results {
                let provider = result.itemProvider

                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let file = await loadItem(provider: provider, type: UTType.image) {
                        files.append(file)
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    if let file = await loadItem(provider: provider, type: UTType.movie) {
                        files.append(file)
                    }
                }
            }
            pickContinuation?.resume(returning: files)
            pickContinuation = nil
        }
    }

    private func loadItem(provider: NSItemProvider, type: UTType) async -> MediaFile? {
        return await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                guard let url, error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                let tempDir = FileManager.default.temporaryDirectory
                let destURL = tempDir.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: destURL)
                do {
                    try FileManager.default.copyItem(at: url, to: destURL)
                    let attrs = try FileManager.default.attributesOfItem(atPath: destURL.path)
                    let size = (attrs[.size] as? Int) ?? 0
                    let mimeType = type == .image ? "image/jpeg" : "video/mp4"
                    let file = MediaFile(
                        name: destURL.lastPathComponent,
                        path: destURL.path,
                        mimeType: mimeType,
                        size: size
                    )
                    continuation.resume(returning: file)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
#endif
