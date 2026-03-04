---
sidebar_position: 1
---

# Web Platform Guide

Setting up RynBridge in your web application.

## Basic Setup

```typescript
import { RynBridge, WebViewTransport } from '@rynbridge/core';
import { DeviceModule } from '@rynbridge/device';
import { StorageModule } from '@rynbridge/storage';
import { UIModule } from '@rynbridge/ui';

const transport = new WebViewTransport();
const bridge = new RynBridge({ timeout: 30000 }, transport);

export const device = new DeviceModule(bridge);
export const storage = new StorageModule(bridge);
export const ui = new UIModule(bridge);
```

## Configuration

```typescript
const bridge = new RynBridge({
  timeout: 30000,   // Request timeout in ms (default: 30000)
  version: '1.0.0', // SDK version for negotiation
}, transport);
```

## Error Handling

```typescript
import { BridgeError, ErrorCode } from '@rynbridge/core';

try {
  const info = await device.getInfo();
} catch (error) {
  if (error instanceof BridgeError) {
    switch (error.code) {
      case ErrorCode.TIMEOUT:
        console.error('Request timed out');
        break;
      case ErrorCode.MODULE_NOT_FOUND:
        console.error('Module not registered on native');
        break;
      default:
        console.error(`Bridge error: ${error.message}`);
    }
  }
}
```

## Testing with MockTransport

```typescript
import { RynBridge, MockTransport } from '@rynbridge/core';
import { DeviceModule } from '@rynbridge/device';

const transport = new MockTransport();
const bridge = new RynBridge({}, transport);
const device = new DeviceModule(bridge);

// Simulate a native response
transport.simulateIncoming(JSON.stringify({
  id: transport.sent[0]?.id,
  status: 'success',
  payload: { platform: 'ios', osVersion: '17.0', model: 'iPhone 15', appVersion: '1.0.0' },
  error: null,
}));
```

## Bundle Size

| Package | Gzipped |
|---------|---------|
| `@rynbridge/core` | < 5KB |
| Individual modules | < 3KB each |
