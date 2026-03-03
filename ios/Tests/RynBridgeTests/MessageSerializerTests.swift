import XCTest
@testable import RynBridge

final class MessageSerializerTests: XCTestCase {
    func testCreateRequestGeneratesUUID() {
        let serializer = MessageSerializer(version: "0.1.0")
        let request = serializer.createRequest(module: "device", action: "getInfo")
        XCTAssertFalse(request.id.isEmpty)
        XCTAssertEqual(request.module, "device")
        XCTAssertEqual(request.action, "getInfo")
        XCTAssertEqual(request.version, "0.1.0")
        XCTAssertTrue(request.payload.isEmpty)
    }

    func testCreateRequestWithPayload() {
        let serializer = MessageSerializer()
        let request = serializer.createRequest(module: "storage", action: "set", payload: ["key": "test", "value": "hello"])
        XCTAssertEqual(request.payload["key"]?.stringValue, "test")
        XCTAssertEqual(request.payload["value"]?.stringValue, "hello")
    }

    func testSerializeRequest() throws {
        let serializer = MessageSerializer(version: "0.1.0")
        let request = BridgeRequest(id: "test-id", module: "device", action: "getInfo", version: "0.1.0")
        let json = try serializer.serialize(request)
        XCTAssertTrue(json.contains("\"id\":\"test-id\""))
        XCTAssertTrue(json.contains("\"module\":\"device\""))
        XCTAssertTrue(json.contains("\"action\":\"getInfo\""))
    }

    func testSerializeResponse() throws {
        let serializer = MessageSerializer()
        let response = BridgeResponse(id: "test-id", status: .success, payload: ["value": "hello"])
        let json = try serializer.serialize(response)
        XCTAssertTrue(json.contains("\"id\":\"test-id\""))
        XCTAssertTrue(json.contains("\"status\":\"success\""))
    }

    func testEachRequestGetsUniqueID() {
        let serializer = MessageSerializer()
        let r1 = serializer.createRequest(module: "m", action: "a")
        let r2 = serializer.createRequest(module: "m", action: "a")
        XCTAssertNotEqual(r1.id, r2.id)
    }

    func testCreateResponseWithError() throws {
        let serializer = MessageSerializer()
        let errorData = BridgeErrorData(code: "TIMEOUT", message: "Request timed out")
        let response = serializer.createResponse(id: "r1", status: .error, error: errorData)
        XCTAssertEqual(response.status, .error)
        XCTAssertEqual(response.error?.code, "TIMEOUT")
        let json = try serializer.serialize(response)
        XCTAssertTrue(json.contains("TIMEOUT"))
    }
}
