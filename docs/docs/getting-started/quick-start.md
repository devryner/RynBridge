---
sidebar_position: 2
---

# Quick Start

Set up a basic RynBridge integration in 3 steps.

## 1. Create the Bridge

```typescript
import { RynBridge, WebViewTransport } from '@rynbridge/core';

const transport = new WebViewTransport();
const bridge = new RynBridge({}, transport);
```

## 2. Use a Module

```typescript
import { DeviceModule } from '@rynbridge/device';

const device = new DeviceModule(bridge);

// Request-Response
const info = await device.getInfo();
console.log(info.platform, info.osVersion);

// Fire-and-Forget
device.vibrate({ pattern: [100, 50, 100] });

// Event Stream
const unsubscribe = device.onBatteryChange((battery) => {
  console.log(`Battery: ${battery.level}%`);
});
```

## 3. Handle on Native Side

### iOS (Swift)

```swift
import RynBridgeCore
import RynBridgeDevice

let bridge = RynBridge(webView: webView)
let device = DeviceModule(provider: MyDeviceProvider())
bridge.register(module: device)
```

### Android (Kotlin)

```kotlin
import io.rynbridge.core.RynBridge
import io.rynbridge.device.DeviceModule

val bridge = RynBridge(webView)
val device = DeviceModule(MyDeviceProvider())
bridge.register(device)
```

## Communication Patterns

RynBridge supports three communication patterns:

| Pattern | Web API | Description |
|---------|---------|-------------|
| Request-Response | `bridge.call()` → `Promise<T>` | Async round-trip with typed response |
| Fire-and-Forget | `bridge.send()` | One-way message, no response |
| Event Stream | `bridge.onEvent()` | Native pushes events to web |
