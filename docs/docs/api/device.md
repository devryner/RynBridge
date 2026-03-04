---
sidebar_position: 2
---

# Device Module API

`@rynbridge/device` — Device information, sensors, and hardware access.

## Setup

```typescript
import { DeviceModule } from '@rynbridge/device';

const device = new DeviceModule(bridge);
```

## Methods

### `getInfo(): Promise<DeviceInfo>`

Returns device platform, OS version, model, and app version.

```typescript
const info = await device.getInfo();
// { platform: 'ios', osVersion: '17.0', model: 'iPhone 15', appVersion: '1.0.0' }
```

### `getBattery(): Promise<BatteryInfo>`

Returns current battery level and charging status.

```typescript
const battery = await device.getBattery();
// { level: 85, isCharging: true }
```

### `getScreen(): Promise<ScreenInfo>`

Returns screen dimensions, scale, and orientation.

```typescript
const screen = await device.getScreen();
// { width: 390, height: 844, scale: 3, orientation: 'portrait' }
```

### `capturePhoto(payload?): Promise<CapturePhotoResult>`

Captures a photo from the device camera.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `quality` | `number` | No | Image quality (0.0 - 1.0) |
| `camera` | `'front' \| 'back'` | No | Camera to use |

```typescript
const photo = await device.capturePhoto({ quality: 0.8, camera: 'back' });
// { imageBase64: '...', width: 1920, height: 1080 }
```

### `getLocation(): Promise<LocationInfo>`

Returns the current GPS location.

```typescript
const location = await device.getLocation();
// { latitude: 37.7749, longitude: -122.4194, accuracy: 10 }
```

### `authenticate(payload): Promise<AuthenticateResult>`

Triggers biometric authentication (Face ID / fingerprint).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `reason` | `string` | Yes | Reason displayed to user |

```typescript
const result = await device.authenticate({ reason: 'Verify your identity' });
// { success: true }
```

### `vibrate(payload?): void`

Triggers device vibration. Fire-and-forget.

```typescript
device.vibrate({ pattern: [100, 50, 100] });
```

## Event Subscriptions

### `onBatteryChange(listener): () => void`

Subscribe to battery level changes. Returns an unsubscribe function.

```typescript
const unsubscribe = device.onBatteryChange((battery) => {
  console.log(`Battery: ${battery.level}%, charging: ${battery.isCharging}`);
});

// Later: stop listening
unsubscribe();
```

### `onLocationChange(listener): () => void`

Subscribe to location changes.

```typescript
const unsubscribe = device.onLocationChange((location) => {
  console.log(`Location: ${location.latitude}, ${location.longitude}`);
});
```

## Types

```typescript
interface DeviceInfo {
  platform: string;
  osVersion: string;
  model: string;
  appVersion: string;
}

interface BatteryInfo {
  level: number;
  isCharging: boolean;
}

interface ScreenInfo {
  width: number;
  height: number;
  scale: number;
  orientation: string;
}

interface CapturePhotoPayload {
  quality?: number;
  camera?: 'front' | 'back';
}

interface CapturePhotoResult {
  imageBase64: string;
  width: number;
  height: number;
}

interface LocationInfo {
  latitude: number;
  longitude: number;
  accuracy: number;
}

interface AuthenticatePayload {
  reason: string;
}

interface AuthenticateResult {
  success: boolean;
}

interface VibratePayload {
  pattern?: number[];
}
```
