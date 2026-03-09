import Foundation
import RynBridge

public final class DefaultAnalyticsProvider: AnalyticsProvider, @unchecked Sendable {
    private let queue = DispatchQueue(label: "io.rynbridge.analytics")
    private var events: [(name: String, params: [String: AnyCodable], timestamp: Date)] = []
    private var userProperties: [String: String] = [:]
    private var userId: String?
    private var currentScreen: String?
    private var enabled: Bool = true

    public init() {}

    public func logEvent(name: String, params: [String: AnyCodable]) {
        queue.sync {
            guard enabled else { return }
            events.append((name: name, params: params, timestamp: Date()))
        }
    }

    public func setUserProperty(key: String, value: String) {
        queue.sync {
            userProperties[key] = value
        }
    }

    public func setUserId(_ userId: String) {
        queue.sync {
            self.userId = userId
        }
    }

    public func setScreen(name: String) {
        queue.sync {
            self.currentScreen = name
        }
    }

    public func resetUser() {
        queue.sync {
            userId = nil
            userProperties.removeAll()
        }
    }

    public func setEnabled(_ enabled: Bool) async throws -> Bool {
        queue.sync {
            self.enabled = enabled
        }
        return enabled
    }

    public func isEnabled() async throws -> Bool {
        return queue.sync { enabled }
    }
}
