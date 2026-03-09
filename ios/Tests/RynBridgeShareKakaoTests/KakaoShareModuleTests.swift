#if canImport(UIKit)
import XCTest
@testable import RynBridge
@testable import RynBridgeShareKakao

final class KakaoShareModuleTests: XCTestCase {

    func testModuleNameAndVersion() {
        let module = KakaoShareModule()
        XCTAssertEqual(module.name, "kakaoShare")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testModuleHasAllActions() {
        let module = KakaoShareModule()
        let expectedActions = ["isAvailable", "shareFeed", "shareCommerce", "shareList", "shareCustom"]
        for action in expectedActions {
            XCTAssertNotNil(module.actions[action], "Missing action: \(action)")
        }
    }

    func testShareResultToPayload() {
        let result = KakaoShareResult(success: true, sharingUrl: "https://kakao.com/share/123")
        let payload = result.toPayload()
        XCTAssertEqual(payload["success"]?.boolValue, true)
        XCTAssertEqual(payload["sharingUrl"]?.stringValue, "https://kakao.com/share/123")
    }

    func testShareResultToPayloadWithoutUrl() {
        let result = KakaoShareResult(success: false)
        let payload = result.toPayload()
        XCTAssertEqual(payload["success"]?.boolValue, false)
        XCTAssertNil(payload["sharingUrl"])
    }
}
#endif
