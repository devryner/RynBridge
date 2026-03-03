import XCTest
@testable import RynBridge

final class MessageDeserializerTests: XCTestCase {
    let deserializer = MessageDeserializer()

    func testDeserializeRequest() throws {
        let json = """
        {"id":"req-1","module":"device","action":"getInfo","payload":{},"version":"0.1.0"}
        """
        let message = try deserializer.deserialize(json)
        guard case .request(let request) = message else {
            XCTFail("Expected request")
            return
        }
        XCTAssertEqual(request.id, "req-1")
        XCTAssertEqual(request.module, "device")
        XCTAssertEqual(request.action, "getInfo")
        XCTAssertEqual(request.version, "0.1.0")
    }

    func testDeserializeSuccessResponse() throws {
        let json = """
        {"id":"res-1","status":"success","payload":{"value":"hello"},"error":null}
        """
        let message = try deserializer.deserialize(json)
        guard case .response(let response) = message else {
            XCTFail("Expected response")
            return
        }
        XCTAssertEqual(response.id, "res-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["value"]?.stringValue, "hello")
        XCTAssertNil(response.error)
    }

    func testDeserializeErrorResponse() throws {
        let json = """
        {"id":"res-2","status":"error","payload":{},"error":{"code":"TIMEOUT","message":"Request timed out"}}
        """
        let message = try deserializer.deserialize(json)
        guard case .response(let response) = message else {
            XCTFail("Expected response")
            return
        }
        XCTAssertEqual(response.status, .error)
        XCTAssertEqual(response.error?.code, "TIMEOUT")
        XCTAssertEqual(response.error?.message, "Request timed out")
    }

    func testDeserializeInvalidJSON() {
        XCTAssertThrowsError(try deserializer.deserialize("not json")) { error in
            let bridgeError = error as! RynBridgeError
            XCTAssertEqual(bridgeError.code, .invalidMessage)
        }
    }

    func testDeserializeMissingID() {
        let json = """
        {"module":"device","action":"getInfo","payload":{},"version":"0.1.0"}
        """
        XCTAssertThrowsError(try deserializer.deserialize(json)) { error in
            let bridgeError = error as! RynBridgeError
            XCTAssertEqual(bridgeError.code, .invalidMessage)
        }
    }

    func testDeserializeMissingModule() {
        let json = """
        {"id":"req-1","action":"getInfo","payload":{},"version":"0.1.0"}
        """
        XCTAssertThrowsError(try deserializer.deserialize(json)) { error in
            let bridgeError = error as! RynBridgeError
            XCTAssertEqual(bridgeError.code, .invalidMessage)
        }
    }
}
