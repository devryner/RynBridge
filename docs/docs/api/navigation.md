---
sidebar_position: 15
---

# Navigation Module API

`@rynbridge/navigation` — Deep linking, URL schemes, and in-app navigation.

## Setup

```typescript
import { NavigationModule } from '@rynbridge/navigation';

const navigation = new NavigationModule(bridge);
```

## Methods

### `openUrl(payload): Promise<OpenUrlResult>`

Opens a URL in the system browser or a registered URL scheme handler.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | `string` | Yes | URL to open |

```typescript
const result = await navigation.openUrl({ url: 'https://rynbridge.dev' });
// { opened: true }
```

### `canOpenUrl(payload): Promise<CanOpenUrlResult>`

Checks whether a URL can be handled by the device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | `string` | Yes | URL to check |

```typescript
const { canOpen } = await navigation.canOpenUrl({ url: 'myapp://profile/123' });
if (canOpen) {
  await navigation.openUrl({ url: 'myapp://profile/123' });
}
```

### `getInitialUrl(): Promise<InitialUrlResult>`

Returns the URL that launched the app (e.g., a deep link from cold start). Returns `null` if the app was not opened via a URL.

```typescript
const { url } = await navigation.getInitialUrl();
if (url) {
  console.log('App opened via:', url);
}
```

### `onDeepLink(listener): () => void`

Subscribes to incoming deep link events while the app is running. Returns an unsubscribe function.

```typescript
const unsubscribe = navigation.onDeepLink((event) => {
  console.log('Deep link received:', event.url);
});

// Later: stop listening
unsubscribe();
```

## Types

```typescript
interface OpenUrlPayload {
  url: string;
}

interface OpenUrlResult {
  opened: boolean;
}

interface CanOpenUrlPayload {
  url: string;
}

interface CanOpenUrlResult {
  canOpen: boolean;
}

interface InitialUrlResult {
  url: string | null;
}

interface DeepLinkEvent {
  url: string;
}
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `NavigationProvider` | `openUrl`, `canOpenUrl`, `getInitialUrl` |
| Android | `NavigationProvider` | Same as iOS |
