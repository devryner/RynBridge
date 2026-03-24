# RynBridge

A lightweight, modular bridge framework for **Web ↔ Native** communication in WebView-based hybrid apps.

RynBridge standardizes the communication interface between Web (TypeScript) and Native (iOS/Android), allowing you to install only the modules you need.

## Features

- **Modular** — Install only the modules your app needs. Core is ~5KB gzipped.
- **Type-safe** — End-to-end type safety across TypeScript, Swift, and Kotlin.
- **Consistent API** — Same interface shape on all three platforms.
- **Promise-based** — Async request-response, event streams, and fire-and-forget patterns.
- **Contract-first** — JSON Schema definitions are the single source of truth.

## Platform Support

| Platform | Minimum Version | Package Manager |
|----------|----------------|-----------------|
| Web | ES2022+ | npm (`@rynbridge/*`) |
| iOS | iOS 17+ | Swift Package Manager |
| Android | API 30+ | Gradle (`com.devryner.rynbridge`) |

---

## Installation

### Web (npm)

```bash
npm install @rynbridge/core

# Add modules as needed
npm install @rynbridge/device @rynbridge/storage @rynbridge/ui
```

### iOS (Swift Package Manager)

**File → Add Package Dependencies** → Enter the repository URL:

```
https://github.com/devryner/RynBridge.git
```

Select the products you need: `RynBridge`, `RynBridgeDevice`, `RynBridgeStorage`, etc.

### Android (Gradle)

```kotlin
dependencies {
    implementation("com.devryner.rynbridge:core:0.1.0")
    implementation("com.devryner.rynbridge:device:0.1.0")
    implementation("com.devryner.rynbridge:storage:0.1.0")
}
```

---

## Quick Start

### Web

```typescript
import { DeviceModule } from '@rynbridge/device';
import { StorageModule } from '@rynbridge/storage';

const device = new DeviceModule();
const storage = new StorageModule();

const info = await device.getInfo();
console.log(info.platform, info.model);

device.vibrate();
```

### iOS

```swift
import RynBridge
import RynBridgeDevice
import RynBridgeStorage

let bridge = RynBridge(webView: webView)

bridge.register(DeviceModule())
bridge.register(StorageModule())
```

### Android

```kotlin
import com.devryner.rynbridge.core.RynBridge
import com.devryner.rynbridge.device.DeviceModule
import com.devryner.rynbridge.storage.StorageModule

val bridge = RynBridge(webView)

bridge.register(DeviceModule(context))
bridge.register(StorageModule(context))
```

Custom providers can be injected on all native platforms:

```swift
bridge.register(DeviceModule(provider: MyCustomDeviceProvider()))  // iOS
```
```kotlin
bridge.register(DeviceModule(MyCustomDeviceProvider()))            // Android
```

---

## Modules

| Module | Package | Description |
|--------|---------|-------------|
| **Core** | `@rynbridge/core` | Bridge protocol, transport, serialization |
| **Device** | `@rynbridge/device` | Device info, battery, screen, vibration |
| **Storage** | `@rynbridge/storage` | Key-value storage (UserDefaults / SharedPreferences) |
| **Secure Storage** | `@rynbridge/secure-storage` | Encrypted storage (Keychain / KeyStore) |
| **UI** | `@rynbridge/ui` | Alerts, confirms, toasts, action sheets |
| **Auth** | `@rynbridge/auth` | OAuth login, token management |
| **Push** | `@rynbridge/push` | Push notification registration & events |
| **Payment** | `@rynbridge/payment` | In-app purchases & transactions |
| **Media** | `@rynbridge/media` | Audio playback, recording, media picker |
| **Crypto** | `@rynbridge/crypto` | Key generation, encryption (AES-GCM) |
| **Share** | `@rynbridge/share` | Native share sheet |
| **Contacts** | `@rynbridge/contacts` | Read/write device contacts |
| **Calendar** | `@rynbridge/calendar` | Calendar event management |
| **Navigation** | `@rynbridge/navigation` | URL opening, deep links, app state |
| **WebView** | `@rynbridge/webview` | Embedded WebView management |
| **Speech** | `@rynbridge/speech` | Speech recognition (STT) & TTS |
| **Analytics** | `@rynbridge/analytics` | Event tracking & user properties |
| **Translation** | `@rynbridge/translation` | Text translation & language detection |
| **Bluetooth** | `@rynbridge/bluetooth` | BLE scanning, connection, read/write |
| **Health** | `@rynbridge/health` | HealthKit / Health Connect |
| **Background Task** | `@rynbridge/background-task` | Background task scheduling |

### Platform-specific

| Module | Package | Platform |
|--------|---------|----------|
| **Push FCM** | `@rynbridge/push-fcm` | Android / iOS (Firebase) |
| **Push APNs** | `RynBridgePushAPNs` | iOS only |
| **Share Kakao** | `@rynbridge/share-kakao` | Android / iOS (KakaoSDK) |
| **Auth Google** | `auth-google` | Android (Credential Manager) |
| **Auth Kakao** | `auth-kakao` | Android (KakaoSDK) |
| **Auth Apple** | `RynBridgeAuthApple` | iOS (Sign in with Apple) |
| **Payment StoreKit** | `RynBridgePaymentStoreKit` | iOS (StoreKit 2) |
| **Payment Google Play** | `payment-google-play` | Android (Play Billing) |

---

## Error Handling

```typescript
import { RynBridgeError } from '@rynbridge/core';

try {
  await device.getInfo();
} catch (error) {
  if (error instanceof RynBridgeError) {
    console.log(error.code);    // "TIMEOUT", "MODULE_NOT_FOUND", etc.
    console.log(error.message);
  }
}
```

| Error Code | Description |
|-----------|-------------|
| `TIMEOUT` | Request timed out (default: 30s) |
| `MODULE_NOT_FOUND` | Module not registered on native side |
| `ACTION_NOT_FOUND` | Action not found in module |
| `TRANSPORT_ERROR` | Transport layer error |
| `VERSION_MISMATCH` | Incompatible Web/Native versions |

---

## Documentation

- [Module API Reference](docs/MODULES.md) — Detailed API for all modules
- [Architecture](docs/ARCHITECTURE.md) — Message protocol, transport layer, provider pattern
- [Development Guide](docs/DEVELOPMENT.md) — Build commands, project structure, playground

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
