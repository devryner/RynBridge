#if canImport(NaturalLanguage)
import Foundation
import NaturalLanguage
import RynBridge

@available(iOS 17.0, macOS 14.0, *)
public final class DefaultTranslationProvider: TranslationProvider, @unchecked Sendable {

    public init() {}

    public func translate(text: String, source: String, target: String) async throws -> TranslateResult {
        throw RynBridgeError(code: .unknown, message: "translate requires iOS 18.0+ with Translation framework, or use a custom TranslationProvider.")
    }

    public func translateBatch(texts: [String], source: String, target: String) async throws -> TranslateBatchResult {
        throw RynBridgeError(code: .unknown, message: "translateBatch requires iOS 18.0+ with Translation framework, or use a custom TranslationProvider.")
    }

    public func detectLanguage(text: String) async throws -> DetectLanguageResult {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else {
            return DetectLanguageResult(language: "und", confidence: 0.0)
        }
        let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
        let confidence = hypotheses[language] ?? 0.0
        return DetectLanguageResult(language: language.rawValue, confidence: confidence)
    }

    public func getSupportedLanguages() async throws -> GetSupportedLanguagesResult {
        let languages = [
            "en", "es", "fr", "de", "it", "pt", "zh-Hans", "ja", "ko", "ru",
            "ar", "hi", "th", "vi", "tr", "pl", "nl", "sv", "da", "fi",
        ]
        return GetSupportedLanguagesResult(languages: languages)
    }

    public func downloadModel(language: String) async throws -> DownloadModelResult {
        throw RynBridgeError(code: .unknown, message: "Model download requires iOS 18.0+ with Translation framework.")
    }

    public func deleteModel(language: String) async throws -> DeleteModelResult {
        throw RynBridgeError(code: .unknown, message: "Model deletion requires iOS 18.0+ with Translation framework.")
    }

    public func getDownloadedModels() async throws -> GetDownloadedModelsResult {
        return GetDownloadedModelsResult(models: [])
    }
}
#endif
