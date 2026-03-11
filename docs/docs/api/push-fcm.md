---
sidebar_position: 23
---

# Push FCM Module API

`@rynbridge/push-fcm` — Firebase Cloud Messaging integration for push notifications.

This is a **platform-specific** module that provides Firebase-backed push notification support. Use this instead of the generic Push module when your app uses Firebase.

## Setup

### iOS (Package.swift)

```swift
.product(name: "RynBridgePushFCM", package: "RynBridge")
```

### Android (build.gradle.kts)

```kotlin
implementation(project(":push-fcm"))
```

### Web

```typescript
import { PushModule } from '@rynbridge/push';

const push = new PushModule(bridge);
```

The Web SDK uses the same `PushModule` — the FCM-specific behavior is handled natively.

## Native Registration

### iOS

```swift
import RynBridgePushFCM

let pushFCM = PushFCMModule(provider: DefaultPushFCMProvider())
bridge.register(pushFCM)
```

### Android

```kotlin
import io.rynbridge.push.fcm.PushFCMModule
import io.rynbridge.push.fcm.FirebasePushFCMProvider

val pushFCM = PushFCMModule(FirebasePushFCMProvider())
bridge.register(pushFCM)
```

## Methods

### `getToken(): Promise<TokenResult>`

Returns the current FCM registration token.

```typescript
const { token } = await push.call('push-fcm', 'getToken', {});
```

### `deleteToken(): Promise<void>`

Deletes the current FCM registration token.

### `subscribeToTopic(payload): Promise<void>`

Subscribes to an FCM topic.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `topic` | `string` | Yes | Topic name |

### `unsubscribeFromTopic(payload): Promise<void>`

Unsubscribes from an FCM topic.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `topic` | `string` | Yes | Topic name |

### `getAutoInitEnabled(): Promise<AutoInitResult>`

Returns whether FCM auto-initialization is enabled.

### `setAutoInitEnabled(payload): Promise<void>`

Enables or disables FCM auto-initialization.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `enabled` | `boolean` | Yes | Enable/disable auto-init |

## Types

```typescript
interface TokenResult {
  token: string;
}

interface TopicPayload {
  topic: string;
}

interface AutoInitResult {
  enabled: boolean;
}

interface SetAutoInitPayload {
  enabled: boolean;
}
```

## Native Provider

| Platform | Protocol/Interface | Default Provider |
|----------|-------------------|-----------------|
| iOS | `PushFCMProvider` | `DefaultPushFCMProvider` (Firebase iOS SDK) |
| Android | `PushFCMProvider` | `FirebasePushFCMProvider` (Firebase Android SDK) |
