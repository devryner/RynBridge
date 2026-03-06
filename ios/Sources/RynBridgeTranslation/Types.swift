import Foundation
import RynBridge

public struct TranslateResult: Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "text": .string(text),
        ]
    }
}

public struct TranslateBatchResult: Sendable {
    public let results: [String]

    public init(results: [String]) {
        self.results = results
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "results": .array(results.map { .string($0) }),
        ]
    }
}

public struct DetectLanguageResult: Sendable {
    public let language: String
    public let confidence: Double

    public init(language: String, confidence: Double) {
        self.language = language
        self.confidence = confidence
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "language": .string(language),
            "confidence": .double(confidence),
        ]
    }
}

public struct GetSupportedLanguagesResult: Sendable {
    public let languages: [String]

    public init(languages: [String]) {
        self.languages = languages
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "languages": .array(languages.map { .string($0) }),
        ]
    }
}

public struct DownloadModelResult: Sendable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "success": .bool(success),
        ]
    }
}

public struct DeleteModelResult: Sendable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "success": .bool(success),
        ]
    }
}

public struct GetDownloadedModelsResult: Sendable {
    public let models: [String]

    public init(models: [String]) {
        self.models = models
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "models": .array(models.map { .string($0) }),
        ]
    }
}

public struct DownloadProgressEvent: Sendable {
    public let language: String
    public let progress: Double

    public init(language: String, progress: Double) {
        self.language = language
        self.progress = progress
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "language": .string(language),
            "progress": .double(progress),
        ]
    }
}

public protocol TranslationProvider: Sendable {
    func translate(text: String, source: String, target: String) async throws -> TranslateResult
    func translateBatch(texts: [String], source: String, target: String) async throws -> TranslateBatchResult
    func detectLanguage(text: String) async throws -> DetectLanguageResult
    func getSupportedLanguages() async throws -> GetSupportedLanguagesResult
    func downloadModel(language: String) async throws -> DownloadModelResult
    func deleteModel(language: String) async throws -> DeleteModelResult
    func getDownloadedModels() async throws -> GetDownloadedModelsResult
}
