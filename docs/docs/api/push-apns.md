---
sidebar_position: 24
---

# Push APNs Module API

`@rynbridge/push-apns` — Apple Push Notification service (APNs) integration for iOS push notifications.

This is a **platform-specific** iOS-only module that provides APNs-specific features like badge management and delivered notification control. Use alongside the generic Push module for basic push functionality.

## Setup

### iOS (Package.swift)

```swift
.product(name: "RynBridgePushAPNs", package: "RynBridge")
```

### Web

```typescript
import { PushModule } from '@rynbridge/push';

const push = new PushModule(bridge);
```

The Web SDK uses the same `PushModule` — the APNs-specific behavior is handled natively.

## Native Registration

### iOS

```swift
import RynBridgePush
import RynBridgePushAPNs

let apnsProvider = DefaultAPNsPushProvider(eventEmitter: bridge.eventEmitter)

// Register base push module with APNs provider
bridge.register(PushModule(provider: apnsProvider))

// Register APNs-specific module
bridge.register(PushAPNsModule(provider: apnsProvider))
```

### AppDelegate Integration

```swift
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    apnsProvider.setDeviceToken(deviceToken)
}

func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    let content = notification.request.content
    apnsProvider.handleNotificationReceived(title: content.title, body: content.body)
    return [.banner, .sound]
}

func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse) async {
    let content = response.notification.request.content
    apnsProvider.handleNotificationOpened(title: content.title, body: content.body)
}
```

## Methods

### `getToken(): Promise<TokenResult>`

Returns the current APNs device token (hex-encoded).

```typescript
const { token } = await bridge.call('push-apns', 'getToken', {});
```

### `setBadgeCount(payload): Promise<void>`

Sets the app icon badge number.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `count` | `number` | Yes | Badge count to set |

```typescript
await bridge.call('push-apns', 'setBadgeCount', { count: 3 });
```

### `getBadgeCount(): Promise<BadgeResult>`

Returns the current app icon badge count.

```typescript
const { count } = await bridge.call('push-apns', 'getBadgeCount', {});
```

### `removeAllDeliveredNotifications(): Promise<void>`

Removes all delivered notifications from Notification Center.

```typescript
await bridge.call('push-apns', 'removeAllDeliveredNotifications', {});
```

### `getDeliveredNotificationCount(): Promise<CountResult>`

Returns the number of delivered notifications in Notification Center.

```typescript
const { count } = await bridge.call('push-apns', 'getDeliveredNotificationCount', {});
```

## Types

```typescript
interface TokenResult {
  token: string | null;
}

interface BadgePayload {
  count: number;
}

interface BadgeResult {
  count: number;
}

interface CountResult {
  count: number;
}
```

## Events

Events are emitted through the base Push module (`push`):

| Event | Description |
|-------|-------------|
| `push:tokenRefresh` | Device token has changed |
| `push:notification` | Notification received in foreground |
| `push:notificationOpened` | User tapped a notification |

## Native Provider

| Platform | Protocol | Default Provider |
|----------|----------|-----------------|
| iOS | `APNsPushProvider` | `DefaultAPNsPushProvider` |

The `DefaultAPNsPushProvider` also implements `PushProvider`, so it can serve both the base `PushModule` and `PushAPNsModule`.
