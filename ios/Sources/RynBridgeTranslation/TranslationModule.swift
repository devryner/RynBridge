import Foundation
import RynBridge

public struct TranslationModule: BridgeModule, Sendable {
    public let name = "translation"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: TranslationProvider) {
        actions = [
            "translate": { payload in
                guard let text = payload["text"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: text")
                }
                guard let source = payload["source"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: source")
                }
                guard let target = payload["target"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: target")
                }
                let result = try await provider.translate(text: text, source: source, target: target)
                return result.toPayload()
            },
            "translateBatch": { payload in
                guard let textsArray = payload["texts"]?.arrayValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: texts")
                }
                let texts = textsArray.compactMap { $0.stringValue }
                guard let source = payload["source"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: source")
                }
                guard let target = payload["target"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: target")
                }
                let result = try await provider.translateBatch(texts: texts, source: source, target: target)
                return result.toPayload()
            },
            "detectLanguage": { payload in
                guard let text = payload["text"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: text")
                }
                let result = try await provider.detectLanguage(text: text)
                return result.toPayload()
            },
            "getSupportedLanguages": { _ in
                let result = try await provider.getSupportedLanguages()
                return result.toPayload()
            },
            "downloadModel": { payload in
                guard let language = payload["language"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: language")
                }
                let result = try await provider.downloadModel(language: language)
                return result.toPayload()
            },
            "deleteModel": { payload in
                guard let language = payload["language"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: language")
                }
                let result = try await provider.deleteModel(language: language)
                return result.toPayload()
            },
            "getDownloadedModels": { _ in
                let result = try await provider.getDownloadedModels()
                return result.toPayload()
            },
        ]
    }
}
