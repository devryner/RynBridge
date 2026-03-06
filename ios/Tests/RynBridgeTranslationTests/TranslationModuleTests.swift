import XCTest
@testable import RynBridge
@testable import RynBridgeTranslation

final class TranslationModuleTests: XCTestCase {
    func testTranslate() async throws {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        let handler = module.actions["translate"]!

        let result = try await handler([
            "text": .string("Hello"),
            "source": .string("en"),
            "target": .string("ko"),
        ])
        XCTAssertEqual(result["text"]?.stringValue, "Translated: Hello")
        XCTAssertEqual(provider.lastTranslateText, "Hello")
        XCTAssertEqual(provider.lastTranslateSource, "en")
        XCTAssertEqual(provider.lastTranslateTarget, "ko")
    }

    func testTranslateBatch() async throws {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        let handler = module.actions["translateBatch"]!

        let result = try await handler([
            "texts": .array([.string("Hello"), .string("World")]),
            "source": .string("en"),
            "target": .string("ko"),
        ])
        let results = result["results"]?.arrayValue
        XCTAssertNotNil(results)
        XCTAssertEqual(results?.count, 2)
        XCTAssertEqual(results?[0].stringValue, "Translated: Hello")
        XCTAssertEqual(results?[1].stringValue, "Translated: World")
    }

    func testDetectLanguage() async throws {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        let handler = module.actions["detectLanguage"]!

        let result = try await handler(["text": .string("Bonjour")])
        XCTAssertEqual(result["language"]?.stringValue, "fr")
        XCTAssertEqual(result["confidence"]?.doubleValue, 0.95)
    }

    func testGetSupportedLanguages() async throws {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        let handler = module.actions["getSupportedLanguages"]!

        let result = try await handler([:])
        let languages = result["languages"]?.arrayValue
        XCTAssertNotNil(languages)
        XCTAssertEqual(languages?.count, 3)
        XCTAssertEqual(languages?[0].stringValue, "en")
        XCTAssertEqual(languages?[1].stringValue, "ko")
        XCTAssertEqual(languages?[2].stringValue, "fr")
    }

    func testDownloadModel() async throws {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        let handler = module.actions["downloadModel"]!

        let result = try await handler(["language": .string("ko")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastDownloadedLanguage, "ko")
    }

    func testDeleteModel() async throws {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        let handler = module.actions["deleteModel"]!

        let result = try await handler(["language": .string("ko")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastDeletedLanguage, "ko")
    }

    func testGetDownloadedModels() async throws {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        let handler = module.actions["getDownloadedModels"]!

        let result = try await handler([:])
        let models = result["models"]?.arrayValue
        XCTAssertNotNil(models)
        XCTAssertEqual(models?.count, 2)
        XCTAssertEqual(models?[0].stringValue, "en")
        XCTAssertEqual(models?[1].stringValue, "ko")
    }

    func testModuleNameAndVersion() {
        let provider = MockTranslationProvider()
        let module = TranslationModule(provider: provider)
        XCTAssertEqual(module.name, "translation")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockTranslationProvider: TranslationProvider, @unchecked Sendable {
    var lastTranslateText: String?
    var lastTranslateSource: String?
    var lastTranslateTarget: String?
    var lastDownloadedLanguage: String?
    var lastDeletedLanguage: String?

    func translate(text: String, source: String, target: String) async throws -> TranslateResult {
        lastTranslateText = text
        lastTranslateSource = source
        lastTranslateTarget = target
        return TranslateResult(text: "Translated: \(text)")
    }

    func translateBatch(texts: [String], source: String, target: String) async throws -> TranslateBatchResult {
        TranslateBatchResult(results: texts.map { "Translated: \($0)" })
    }

    func detectLanguage(text: String) async throws -> DetectLanguageResult {
        DetectLanguageResult(language: "fr", confidence: 0.95)
    }

    func getSupportedLanguages() async throws -> GetSupportedLanguagesResult {
        GetSupportedLanguagesResult(languages: ["en", "ko", "fr"])
    }

    func downloadModel(language: String) async throws -> DownloadModelResult {
        lastDownloadedLanguage = language
        return DownloadModelResult(success: true)
    }

    func deleteModel(language: String) async throws -> DeleteModelResult {
        lastDeletedLanguage = language
        return DeleteModelResult(success: true)
    }

    func getDownloadedModels() async throws -> GetDownloadedModelsResult {
        GetDownloadedModelsResult(models: ["en", "ko"])
    }
}
