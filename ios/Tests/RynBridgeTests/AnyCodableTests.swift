import XCTest
@testable import RynBridge

final class AnyCodableTests: XCTestCase {
    func testEncodeAndDecodeString() throws {
        let value: AnyCodable = "hello"
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded, .string("hello"))
        XCTAssertEqual(decoded.stringValue, "hello")
    }

    func testEncodeAndDecodeInt() throws {
        let value: AnyCodable = 42
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded, .int(42))
        XCTAssertEqual(decoded.intValue, 42)
    }

    func testEncodeAndDecodeBool() throws {
        let value: AnyCodable = true
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded, .bool(true))
        XCTAssertEqual(decoded.boolValue, true)
    }

    func testEncodeAndDecodeDouble() throws {
        let value: AnyCodable = 3.14
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.doubleValue!, 3.14, accuracy: 0.001)
    }

    func testEncodeAndDecodeNull() throws {
        let value: AnyCodable = nil
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertTrue(decoded.isNull)
    }

    func testEncodeAndDecodeArray() throws {
        let value: AnyCodable = [1, 2, 3]
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.arrayValue?.count, 3)
    }

    func testEncodeAndDecodeDictionary() throws {
        let value: AnyCodable = ["key": "value"]
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.dictionaryValue?["key"]?.stringValue, "value")
    }

    func testNestedStructure() throws {
        let json = """
        {"name": "test", "count": 5, "active": true, "items": [1, 2], "meta": {"key": "val"}}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: json)
        XCTAssertEqual(decoded["name"]?.stringValue, "test")
        XCTAssertEqual(decoded["count"]?.intValue, 5)
        XCTAssertEqual(decoded["active"]?.boolValue, true)
        XCTAssertEqual(decoded["items"]?.arrayValue?.count, 2)
        XCTAssertEqual(decoded["meta"]?.dictionaryValue?["key"]?.stringValue, "val")
    }
}
