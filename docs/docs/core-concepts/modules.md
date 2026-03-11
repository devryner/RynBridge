---
sidebar_position: 3
---

# Modules

RynBridge uses a modular architecture. Each module provides a focused set of native capabilities.

## Module Structure

Every module follows the same pattern:

1. Wraps a `RynBridge` instance via constructor injection
2. Defines a `MODULE` constant (e.g., `'device'`)
3. Methods delegate to `bridge.call()` or `bridge.send()`
4. Types are defined in `types.ts` and re-exported from `index.ts`

## Available Modules

### Phase 1 (Implemented)

| Module | Package | Description |
|--------|---------|-------------|
| Core | `@rynbridge/core` | Message transport, callbacks, events |
| Device | `@rynbridge/device` | Device info, battery, location, camera |
| Storage | `@rynbridge/storage` | Key-value store + file system |
| Secure Storage | `@rynbridge/secure-storage` | Encrypted key-value store |
| UI | `@rynbridge/ui` | Alerts, toasts, action sheets, keyboard |

### Phase 2 (Implemented)

| Module | Package | Description |
|--------|---------|-------------|
| Auth | `@rynbridge/auth` | OAuth login, token management |
| Push | `@rynbridge/push` | Push notification registration & handling |
| Payment | `@rynbridge/payment` | In-app purchases (StoreKit 2 / Google Play Billing) |
| Media | `@rynbridge/media` | Audio playback, recording, media picker |
| Crypto | `@rynbridge/crypto` | Key exchange, E2E encryption (AES-GCM) |

### Phase 3 (Implemented)

| Module | Package | Description |
|--------|---------|-------------|
| Analytics | `@rynbridge/analytics` | Event tracking, screen views |
| Navigation | `@rynbridge/navigation` | Native navigation (push, pop, present) |
| Share | `@rynbridge/share` | System share sheet |
| Health | `@rynbridge/health` | HealthKit / Health Connect |
| Bluetooth | `@rynbridge/bluetooth` | BLE scan, connect, read/write |
| Contacts | `@rynbridge/contacts` | Contact CRUD, picker |
| Calendar | `@rynbridge/calendar` | Calendar & event management |
| Speech | `@rynbridge/speech` | Speech recognition & synthesis |
| Background Task | `@rynbridge/background-task` | Background task scheduling |

### Platform-Specific Modules

| Module | Package | Description |
|--------|---------|-------------|
| Push FCM | `@rynbridge/push-fcm` | Firebase Cloud Messaging |
| Share Kakao | `@rynbridge/share-kakao` | Kakao SDK share |

## Creating a Custom Module

```typescript
import type { RynBridge } from '@rynbridge/core';

const MODULE = 'my-module';

export class MyModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async doSomething(payload: MyPayload): Promise<MyResult> {
    const result = await this.bridge.call(MODULE, 'doSomething', payload);
    return result as unknown as MyResult;
  }

  fireAndForget(payload: MyPayload): void {
    this.bridge.send(MODULE, 'fireAndForget', payload);
  }

  onEvent(listener: (data: MyEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => {
      listener(data as unknown as MyEvent);
    };
    this.bridge.onEvent(`${MODULE}:myEvent`, wrapper);
    return () => this.bridge.offEvent(`${MODULE}:myEvent`, wrapper);
  }
}
```

## Naming Convention

| Platform | Pattern | Example |
|----------|---------|---------|
| npm | `@rynbridge/<module>` | `@rynbridge/device` |
| SPM | `RynBridge<Module>` | `RynBridgeDevice` |
| Gradle | `io.rynbridge:<module>` | `io.rynbridge:device` |
