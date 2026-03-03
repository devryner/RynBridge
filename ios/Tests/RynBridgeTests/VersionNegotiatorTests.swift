import XCTest
@testable import RynBridge

final class VersionNegotiatorTests: XCTestCase {
    let negotiator = VersionNegotiator()

    func testParseValidVersion() throws {
        let v = try negotiator.parse("1.2.3")
        XCTAssertEqual(v.major, 1)
        XCTAssertEqual(v.minor, 2)
        XCTAssertEqual(v.patch, 3)
    }

    func testParseInvalidVersion() {
        XCTAssertThrowsError(try negotiator.parse("invalid")) { error in
            let bridgeError = error as! RynBridgeError
            XCTAssertEqual(bridgeError.code, .versionMismatch)
        }
    }

    func testParseIncompleteVersion() {
        XCTAssertThrowsError(try negotiator.parse("1.2"))
    }

    func testCompatibleSameMajorStable() {
        XCTAssertTrue(negotiator.isCompatible(local: "1.0.0", remote: "1.2.3"))
        XCTAssertTrue(negotiator.isCompatible(local: "2.0.0", remote: "2.5.0"))
    }

    func testIncompatibleDifferentMajorStable() {
        XCTAssertFalse(negotiator.isCompatible(local: "1.0.0", remote: "2.0.0"))
    }

    func testCompatibleSameMinorPrerelease() {
        XCTAssertTrue(negotiator.isCompatible(local: "0.1.0", remote: "0.1.5"))
    }

    func testIncompatibleDifferentMinorPrerelease() {
        XCTAssertFalse(negotiator.isCompatible(local: "0.1.0", remote: "0.2.0"))
    }

    func testAssertCompatibleThrows() {
        XCTAssertThrowsError(try negotiator.assertCompatible(local: "1.0.0", remote: "2.0.0")) { error in
            let bridgeError = error as! RynBridgeError
            XCTAssertEqual(bridgeError.code, .versionMismatch)
        }
    }

    func testAssertCompatiblePasses() {
        XCTAssertNoThrow(try negotiator.assertCompatible(local: "0.1.0", remote: "0.1.3"))
    }

    func testInvalidVersionNotCompatible() {
        XCTAssertFalse(negotiator.isCompatible(local: "bad", remote: "1.0.0"))
    }
}
