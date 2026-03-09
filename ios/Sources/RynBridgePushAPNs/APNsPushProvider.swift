import Foundation
import UserNotifications
import RynBridge
import RynBridgePush

#if canImport(UIKit)
import UIKit

public final class APNsPushProvider: PushProvider, @unchecked Sendable {
    private var deviceToken: String?
    private let eventEmitter: BridgeEventEmitter?
    private var initialNotification: PushNotificationData?

    public init(eventEmitter: BridgeEventEmitter? = nil) {
        self.eventEmitter = eventEmitter
    }

    /// Call this from AppDelegate's `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
    public func setDeviceToken(_ tokenData: Data) {
        let newToken = tokenData.map { String(format: "%02x", $0) }.joined()
        let tokenChanged = deviceToken != nil && deviceToken != newToken
        deviceToken = newToken

        if tokenChanged {
            eventEmitter?("push", "tokenRefresh", ["token": .string(newToken)])
        }
    }

    /// Call this from AppDelegate/SceneDelegate when a push notification is received in foreground
    public func handleNotificationReceived(title: String?, body: String?, data: [String: AnyCodable]? = nil) {
        let payload: [String: AnyCodable] = [
            "title": title.map { .string($0) } ?? .null,
            "body": body.map { .string($0) } ?? .null,
            "data": data.map { .dictionary($0) } ?? .null,
        ]
        eventEmitter?("push", "notification", payload)
    }

    /// Call this when user taps a notification from background/terminated state
    public func handleNotificationOpened(title: String?, body: String?, data: [String: AnyCodable]? = nil) {
        let payload: [String: AnyCodable] = [
            "title": title.map { .string($0) } ?? .null,
            "body": body.map { .string($0) } ?? .null,
            "data": data.map { .dictionary($0) } ?? .null,
        ]
        eventEmitter?("push", "notificationOpened", payload)
    }

    /// Call this from AppDelegate when app launches from a notification tap (cold start)
    public func setInitialNotification(_ notification: PushNotificationData) {
        self.initialNotification = notification
    }

    public func register() async throws -> PushRegistration {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    let token = self?.deviceToken ?? "pending"
                    continuation.resume(returning: PushRegistration(token: token, platform: "ios"))
                }
            }
        }
    }

    public func unregister() async throws {
        await MainActor.run {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
        deviceToken = nil
    }

    public func getToken() async throws -> String? {
        return deviceToken
    }

    public func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }

    public func getPermissionStatus() async throws -> PushPermissionStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let status: String
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            status = "granted"
        case .denied:
            status = "denied"
        case .notDetermined:
            status = "notDetermined"
        @unknown default:
            status = "notDetermined"
        }
        return PushPermissionStatus(status: status)
    }

    public func getInitialNotification() async throws -> PushNotificationData? {
        return initialNotification
    }
}
#endif
