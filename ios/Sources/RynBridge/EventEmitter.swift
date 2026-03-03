import Foundation

public final class EventEmitter: @unchecked Sendable {
    public typealias Listener = @Sendable ([String: AnyCodable]) -> Void

    private let lock = NSLock()
    private var listeners: [String: [ListenerEntry]] = [:]
    private var nextId: UInt64 = 0

    public init() {}

    @discardableResult
    public func on(_ event: String, handler: @escaping Listener) -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        let id = nextId
        nextId += 1
        listeners[event, default: []].append(ListenerEntry(id: id, handler: handler))
        return id
    }

    public func off(_ event: String, id: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        listeners[event]?.removeAll { $0.id == id }
        if listeners[event]?.isEmpty == true {
            listeners.removeValue(forKey: event)
        }
    }

    public func emit(_ event: String, data: [String: AnyCodable]) {
        lock.lock()
        let entries = listeners[event] ?? []
        lock.unlock()
        for entry in entries {
            entry.handler(data)
        }
    }

    public func removeAllListeners(for event: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if let event = event {
            listeners.removeValue(forKey: event)
        } else {
            listeners.removeAll()
        }
    }

    public func listenerCount(for event: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return listeners[event]?.count ?? 0
    }
}

private struct ListenerEntry {
    let id: UInt64
    let handler: EventEmitter.Listener
}
