import Foundation

public final class MockTransport: Transport, @unchecked Sendable {
    private let lock = NSLock()
    private var _sent: [String] = []
    private var messageHandler: (@Sendable (String) -> Void)?

    public init() {}

    public var sent: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _sent
    }

    public func send(_ message: String) {
        lock.lock()
        _sent.append(message)
        lock.unlock()
    }

    public func onMessage(_ handler: @escaping @Sendable (String) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        messageHandler = handler
    }

    public func dispose() {
        lock.lock()
        defer { lock.unlock() }
        messageHandler = nil
    }

    public func simulateIncoming(_ message: String) {
        lock.lock()
        let handler = messageHandler
        lock.unlock()
        handler?(message)
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        _sent.removeAll()
    }
}
