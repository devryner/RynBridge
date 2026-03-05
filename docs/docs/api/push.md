---
sidebar_position: 7
---

# Push Module API

`@rynbridge/push` — Push notification registration, permission management, and notification observation.

## Setup

```typescript
import { PushModule } from '@rynbridge/push';

const push = new PushModule(bridge);
```

## Methods

### `register(): Promise<PushRegistration>`

Registers the device for push notifications and returns the device token.

```typescript
const { token, platform } = await push.register();
// { token: 'fcm-token-abc123', platform: 'ios' }
```

### `unregister(): Promise<void>`

Unregisters the device from push notifications.

```typescript
await push.unregister();
```

### `getToken(): Promise<PushToken>`

Returns the current push token, or `null` if not registered.

```typescript
const { token } = await push.getToken();
```

### `requestPermission(): Promise<PushPermission>`

Requests notification permission from the user.

```typescript
const { granted } = await push.requestPermission();
if (granted) {
  await push.register();
}
```

### `getPermissionStatus(): Promise<PushPermissionStatus>`

Returns the current notification permission status.

```typescript
const { status } = await push.getPermissionStatus();
// status: 'granted' | 'denied' | 'notDetermined'
```

### `onNotification(listener): () => void`

Subscribes to incoming push notifications. Returns an unsubscribe function.

```typescript
const unsub = push.onNotification((notification) => {
  console.log(notification.title, notification.body, notification.data);
});
```

### `onTokenRefresh(listener): () => void`

Subscribes to push token refresh events. Returns an unsubscribe function.

```typescript
const unsub = push.onTokenRefresh(({ token }) => {
  sendTokenToServer(token);
});
```

## Types

```typescript
interface PushRegistration { token: string; platform: string }
interface PushToken { token: string | null }
interface PushPermission { granted: boolean }
interface PushPermissionStatus { status: 'granted' | 'denied' | 'notDetermined' }
interface PushNotification { title: string | null; body: string | null; data: Record<string, unknown> | null }
interface PushTokenRefresh { token: string }
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `PushProvider` | `register`, `unregister`, `getToken`, `requestPermission`, `getPermissionStatus` |
| Android | `PushProvider` | Same as iOS |
