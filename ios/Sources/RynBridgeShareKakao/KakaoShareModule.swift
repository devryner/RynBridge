#if canImport(UIKit)
import Foundation
import UIKit
import RynBridge
import KakaoSDKShare
import KakaoSDKTemplate

public struct KakaoShareModule: BridgeModule, Sendable {
    public let name = "kakaoShare"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init() {
        actions = [
            "isAvailable": { _ in
                let available = await MainActor.run {
                    ShareApi.isKakaoTalkSharingAvailable()
                }
                return ["available": .bool(available)]
            },
            "shareFeed": { payload in
                let template = try KakaoTemplateMapper.feedTemplate(from: payload)
                return try await Self.shareDefault(template: template)
            },
            "shareCommerce": { payload in
                let template = try KakaoTemplateMapper.commerceTemplate(from: payload)
                return try await Self.shareDefault(template: template)
            },
            "shareList": { payload in
                let template = try KakaoTemplateMapper.listTemplate(from: payload)
                return try await Self.shareDefault(template: template)
            },
            "shareCustom": { payload in
                guard let templateId = payload["templateId"]?.intValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: templateId")
                }
                let templateArgs = KakaoTemplateMapper.mapStringDict(payload["templateArgs"])
                let serverCallbackArgs = KakaoTemplateMapper.mapStringDict(payload["serverCallbackArgs"])
                return try await Self.shareCustom(
                    templateId: Int64(templateId),
                    templateArgs: templateArgs,
                    serverCallbackArgs: serverCallbackArgs
                )
            },
        ]
    }

    // MARK: - Share Default Template

    private static func shareDefault(template: Templatable) async throws -> [String: AnyCodable] {
        try await withCheckedThrowingContinuation { continuation in
            ShareApi.shared.shareDefault(templatable: template) { sharingResult, error in
                if let error {
                    continuation.resume(throwing: RynBridgeError(
                        code: .unknown,
                        message: "Kakao share failed: \(error.localizedDescription)"
                    ))
                    return
                }
                guard let sharingResult else {
                    continuation.resume(throwing: RynBridgeError(
                        code: .unknown,
                        message: "Kakao share returned nil result"
                    ))
                    return
                }
                Task { @MainActor in
                    UIApplication.shared.open(sharingResult.url, options: [:]) { success in
                        let result = KakaoShareResult(
                            success: success,
                            sharingUrl: sharingResult.url.absoluteString
                        )
                        continuation.resume(returning: result.toPayload())
                    }
                }
            }
        }
    }

    // MARK: - Share Custom Template

    private static func shareCustom(
        templateId: Int64,
        templateArgs: [String: String]?,
        serverCallbackArgs: [String: String]?
    ) async throws -> [String: AnyCodable] {
        try await withCheckedThrowingContinuation { continuation in
            ShareApi.shared.shareCustom(
                templateId: templateId,
                templateArgs: templateArgs,
                serverCallbackArgs: serverCallbackArgs
            ) { sharingResult, error in
                if let error {
                    continuation.resume(throwing: RynBridgeError(
                        code: .unknown,
                        message: "Kakao custom share failed: \(error.localizedDescription)"
                    ))
                    return
                }
                guard let sharingResult else {
                    continuation.resume(throwing: RynBridgeError(
                        code: .unknown,
                        message: "Kakao custom share returned nil result"
                    ))
                    return
                }
                Task { @MainActor in
                    UIApplication.shared.open(sharingResult.url, options: [:]) { success in
                        let result = KakaoShareResult(
                            success: success,
                            sharingUrl: sharingResult.url.absoluteString
                        )
                        continuation.resume(returning: result.toPayload())
                    }
                }
            }
        }
    }
}
#endif
