import Foundation

public actor CallbackRegistry {
    private var callbacks: [String: CheckedContinuation<BridgeResponse, Error>] = [:]
    private var timeoutTasks: [String: Task<Void, Never>] = [:]

    public init() {}

    public func register(id: String, timeout: TimeInterval) async throws -> BridgeResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BridgeResponse, Error>) in
            Task { self.store(id: id, continuation: continuation, timeout: timeout) }
        }
    }

    private func store(id: String, continuation: CheckedContinuation<BridgeResponse, Error>, timeout: TimeInterval) {
        callbacks[id] = continuation

        let timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.handleTimeout(id: id)
        }
        timeoutTasks[id] = timeoutTask
    }

    private func handleTimeout(id: String) {
        guard let continuation = callbacks.removeValue(forKey: id) else { return }
        timeoutTasks.removeValue(forKey: id)?.cancel()
        continuation.resume(throwing: RynBridgeError(code: .timeout, message: "Request \(id) timed out"))
    }

    public func resolve(id: String, response: BridgeResponse) -> Bool {
        guard let continuation = callbacks.removeValue(forKey: id) else { return false }
        timeoutTasks.removeValue(forKey: id)?.cancel()
        continuation.resume(returning: response)
        return true
    }

    public func clear() {
        for (id, continuation) in callbacks {
            continuation.resume(throwing: RynBridgeError(code: .transportError, message: "Bridge disposed, request \(id) cancelled"))
        }
        callbacks.removeAll()
        for (_, task) in timeoutTasks {
            task.cancel()
        }
        timeoutTasks.removeAll()
    }

    public var pendingCount: Int {
        callbacks.count
    }
}
