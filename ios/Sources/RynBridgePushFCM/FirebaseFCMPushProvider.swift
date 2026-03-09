import Foundation
import RynBridge
import FirebaseMessaging

public final class FirebaseFCMPushProvider: NSObject, FCMPushProvider, @unchecked Sendable {
    private let eventEmitter: BridgeEventEmitter?

    public init(eventEmitter: BridgeEventEmitter? = nil) {
        self.eventEmitter = eventEmitter
        super.init()
        Messaging.messaging().delegate = self
    }

    public func getToken() async throws -> String {
        return try await Messaging.messaging().token()
    }

    public func deleteToken() async throws {
        try await Messaging.messaging().deleteToken()
    }

    public func subscribeToTopic(_ topic: String) async throws {
        try await Messaging.messaging().subscribe(toTopic: topic)
    }

    public func unsubscribeFromTopic(_ topic: String) async throws {
        try await Messaging.messaging().unsubscribe(fromTopic: topic)
    }

    public func getAutoInitEnabled() async throws -> Bool {
        return Messaging.messaging().isAutoInitEnabled
    }

    public func setAutoInitEnabled(_ enabled: Bool) async throws {
        Messaging.messaging().isAutoInitEnabled = enabled
    }
}

extension FirebaseFCMPushProvider: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        eventEmitter?("push-fcm", "tokenRefresh", ["token": .string(token)])
    }
}
