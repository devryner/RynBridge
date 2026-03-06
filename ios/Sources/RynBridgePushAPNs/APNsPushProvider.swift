import Foundation
import UIKit
import UserNotifications
import RynBridge
import RynBridgePush

public final class APNsPushProvider: PushProvider, @unchecked Sendable {
    private var deviceToken: String?

    public init() {}

    /// Call this from AppDelegate's `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
    public func setDeviceToken(_ tokenData: Data) {
        deviceToken = tokenData.map { String(format: "%02x", $0) }.joined()
    }

    public func register() async throws -> PushRegistration {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                // Token will be available via setDeviceToken callback
                // For now return current token or wait briefly
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
        // Initial notification should be stored by AppDelegate when app launches from push
        // This is a placeholder — apps should override with their stored launch notification
        return nil
    }
}
