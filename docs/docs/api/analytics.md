---
sidebar_position: 18
---

# Analytics Module API

`@rynbridge/analytics` — Event tracking and analytics reporting.

## Setup

```typescript
import { AnalyticsModule } from '@rynbridge/analytics';

const analytics = new AnalyticsModule(bridge);
```

## Methods

### `trackEvent(payload): Promise<void>`

Tracks a custom event with optional properties.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | `string` | Yes | Event name |
| `properties` | `Record<string, unknown>` | No | Event properties |

```typescript
await analytics.trackEvent({
  name: 'purchase_completed',
  properties: { amount: 9900, currency: 'KRW' },
});
```

### `trackScreen(payload): Promise<void>`

Tracks a screen view.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | `string` | Yes | Screen name |
| `properties` | `Record<string, unknown>` | No | Additional properties |

```typescript
await analytics.trackScreen({ name: 'ProductDetail', properties: { productId: '123' } });
```

### `setUserId(payload): Promise<void>`

Sets the user ID for analytics tracking.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userId` | `string` | Yes | User identifier |

```typescript
await analytics.setUserId({ userId: 'user-abc-123' });
```

### `setUserProperties(payload): Promise<void>`

Sets user properties for segmentation.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `properties` | `Record<string, unknown>` | Yes | User properties |

```typescript
await analytics.setUserProperties({
  properties: { plan: 'premium', region: 'KR' },
});
```

### `resetUser(): Promise<void>`

Clears user ID and properties.

```typescript
await analytics.resetUser();
```

## Types

```typescript
interface TrackEventPayload {
  name: string;
  properties?: Record<string, unknown>;
}

interface TrackScreenPayload {
  name: string;
  properties?: Record<string, unknown>;
}

interface SetUserIdPayload {
  userId: string;
}

interface SetUserPropertiesPayload {
  properties: Record<string, unknown>;
}
```

## Native Provider

| Platform | Protocol/Interface | Default Provider |
|----------|-------------------|-----------------|
| iOS | `AnalyticsProvider` | `DefaultAnalyticsProvider` (in-memory) |
| Android | `AnalyticsProvider` | `DefaultAnalyticsProvider` (in-memory) |
