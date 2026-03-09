import Foundation
import RynBridge

public struct KakaoShareResult: Sendable {
    public let success: Bool
    public let sharingUrl: String?

    public init(success: Bool, sharingUrl: String? = nil) {
        self.success = success
        self.sharingUrl = sharingUrl
    }

    public func toPayload() -> [String: AnyCodable] {
        var result: [String: AnyCodable] = ["success": .bool(success)]
        if let url = sharingUrl {
            result["sharingUrl"] = .string(url)
        }
        return result
    }
}
