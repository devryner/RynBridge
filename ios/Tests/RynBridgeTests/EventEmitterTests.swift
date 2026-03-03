import XCTest
@testable import RynBridge

final class EventEmitterTests: XCTestCase {
    func testOnAndEmit() {
        let emitter = EventEmitter()
        var received: [String: AnyCodable]?

        emitter.on("test") { data in
            received = data
        }

        emitter.emit("test", data: ["value": "hello"])
        XCTAssertEqual(received?["value"]?.stringValue, "hello")
    }

    func testMultipleListeners() {
        let emitter = EventEmitter()
        var count = 0

        emitter.on("event") { _ in count += 1 }
        emitter.on("event") { _ in count += 1 }

        emitter.emit("event", data: [:])
        XCTAssertEqual(count, 2)
    }

    func testOff() {
        let emitter = EventEmitter()
        var count = 0

        let id = emitter.on("event") { _ in count += 1 }
        emitter.emit("event", data: [:])
        XCTAssertEqual(count, 1)

        emitter.off("event", id: id)
        emitter.emit("event", data: [:])
        XCTAssertEqual(count, 1)
    }

    func testRemoveAllListenersForEvent() {
        let emitter = EventEmitter()
        var count = 0

        emitter.on("event1") { _ in count += 1 }
        emitter.on("event1") { _ in count += 1 }
        emitter.on("event2") { _ in count += 1 }

        emitter.removeAllListeners(for: "event1")
        emitter.emit("event1", data: [:])
        XCTAssertEqual(count, 0)

        emitter.emit("event2", data: [:])
        XCTAssertEqual(count, 1)
    }

    func testRemoveAllListeners() {
        let emitter = EventEmitter()
        var count = 0

        emitter.on("event1") { _ in count += 1 }
        emitter.on("event2") { _ in count += 1 }

        emitter.removeAllListeners()
        emitter.emit("event1", data: [:])
        emitter.emit("event2", data: [:])
        XCTAssertEqual(count, 0)
    }

    func testListenerCount() {
        let emitter = EventEmitter()
        emitter.on("event") { _ in }
        emitter.on("event") { _ in }
        XCTAssertEqual(emitter.listenerCount(for: "event"), 2)
        XCTAssertEqual(emitter.listenerCount(for: "other"), 0)
    }

    func testEmitNonexistentEvent() {
        let emitter = EventEmitter()
        // Should not crash
        emitter.emit("nonexistent", data: [:])
    }
}
