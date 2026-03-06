import Foundation

public final class RynBridge: @unchecked Sendable {
    private let transport: Transport
    private let config: BridgeConfig
    private let serializer: MessageSerializer
    private let deserializer: MessageDeserializer
    private let callbacks: CallbackRegistry
    private let events: EventEmitter
    private let modules: ModuleRegistry
    private let versionNegotiator: VersionNegotiator
    private var disposed = false

    public init(transport: Transport, config: BridgeConfig = .default) {
        self.transport = transport
        self.config = config
        self.serializer = MessageSerializer(version: config.version)
        self.deserializer = MessageDeserializer()
        self.callbacks = CallbackRegistry()
        self.events = EventEmitter()
        self.modules = ModuleRegistry()
        self.versionNegotiator = VersionNegotiator()

        transport.onMessage { [weak self] raw in
            guard let self = self else { return }
            Task { await self.handleIncomingMessage(raw) }
        }
    }

    // MARK: - Module Registration

    public func register(_ module: BridgeModule) {
        modules.register(module)
    }

    // MARK: - Request-Response (Web → Native or Native → Web)

    public func call(_ module: String, action: String, payload: [String: AnyCodable] = [:]) async throws -> [String: AnyCodable] {
        guard !disposed else {
            throw RynBridgeError(code: .transportError, message: "Bridge has been disposed")
        }

        let request = serializer.createRequest(module: module, action: action, payload: payload)
        let json = try serializer.serialize(request)

        transport.send(json)

        let response = try await callbacks.register(id: request.id, timeout: config.timeout)

        if response.status == .error, let error = response.error {
            throw RynBridgeError(
                code: ErrorCode(rawValue: error.code) ?? .unknown,
                message: error.message,
                details: error.details
            )
        }

        return response.payload
    }

    // MARK: - Fire-and-Forget

    public func send(_ module: String, action: String, payload: [String: AnyCodable] = [:]) {
        guard !disposed else { return }

        let request = serializer.createRequest(module: module, action: action, payload: payload)
        guard let json = try? serializer.serialize(request) else { return }

        transport.send(json)
    }

    // MARK: - Event Streams

    @discardableResult
    public func onEvent(_ event: String, handler: @escaping @Sendable ([String: AnyCodable]) -> Void) -> UInt64 {
        events.on(event, handler: handler)
    }

    public func offEvent(_ event: String, id: UInt64) {
        events.off(event, id: id)
    }

    // MARK: - Native → Web Event Emission

    public func emitEvent(_ module: String, action: String, payload: [String: AnyCodable] = [:]) {
        guard !disposed else { return }
        let request = serializer.createRequest(module: module, action: action, payload: payload)
        guard let json = try? serializer.serialize(request) else { return }
        transport.send(json)
    }

    // MARK: - Incoming Message Handling

    private func handleIncomingMessage(_ raw: String) async {
        do {
            let message = try deserializer.deserialize(raw)
            switch message {
            case .response(let response):
                _ = await callbacks.resolve(id: response.id, response: response)

            case .request(let request):
                await handleIncomingRequest(request)
            }
        } catch {
            // Malformed messages are silently dropped
        }
    }

    private func handleIncomingRequest(_ request: BridgeRequest) async {
        do {
            // Version compatibility check
            try versionNegotiator.assertCompatible(local: config.version, remote: request.version)

            let handler = try modules.getAction(module: request.module, action: request.action)
            let result = try await handler(request.payload)

            let response = serializer.createResponse(id: request.id, status: .success, payload: result)
            let json = try serializer.serialize(response)
            transport.send(json)
        } catch let error as RynBridgeError {
            sendErrorResponse(id: request.id, error: error)
        } catch {
            sendErrorResponse(id: request.id, error: RynBridgeError(code: .unknown, message: error.localizedDescription))
        }
    }

    private func sendErrorResponse(id: String, error: RynBridgeError) {
        let response = serializer.createResponse(
            id: id,
            status: .error,
            error: error.errorData
        )
        guard let json = try? serializer.serialize(response) else { return }
        transport.send(json)
    }

    // MARK: - Dispose

    public func dispose() {
        disposed = true
        Task { await callbacks.clear() }
        events.removeAllListeners()
        transport.dispose()
    }
}
