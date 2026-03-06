import Foundation
import RynBridge

public protocol AnalyticsProvider: Sendable {
    func logEvent(name: String, params: [String: AnyCodable])
    func setUserProperty(key: String, value: String)
    func setUserId(_ userId: String)
    func setScreen(name: String)
    func resetUser()
    func setEnabled(_ enabled: Bool) async throws -> Bool
    func isEnabled() async throws -> Bool
}
