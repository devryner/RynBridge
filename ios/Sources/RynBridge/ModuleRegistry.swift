import Foundation

public final class ModuleRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var modules: [String: BridgeModule] = [:]

    public init() {}

    public func register(_ module: BridgeModule) {
        lock.lock()
        defer { lock.unlock() }
        modules[module.name] = module
    }

    public func getAction(module moduleName: String, action actionName: String) throws -> ActionHandler {
        lock.lock()
        defer { lock.unlock() }

        guard let module = modules[moduleName] else {
            throw RynBridgeError(code: .moduleNotFound, message: "Module '\(moduleName)' not found")
        }
        guard let handler = module.actions[actionName] else {
            throw RynBridgeError(code: .actionNotFound, message: "Action '\(actionName)' not found in module '\(moduleName)'")
        }
        return handler
    }

    public func hasModule(_ name: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return modules[name] != nil
    }
}
