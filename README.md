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
| Android | API 30+ | Gradle |

---

## Installation

### Web (npm)

```bash
# Core (required)
npm install @rynbridge/core

# Add modules as needed
npm install @rynbridge/device
npm install @rynbridge/storage
npm install @rynbridge/secure-storage
npm install @rynbridge/ui
```

### iOS (Swift Package Manager)

Add the local package or Git repository in Xcode:

**File → Add Package Dependencies** → Enter the repository URL

Select the products you need:
- `RynBridge` (required)
- `RynBridgeDevice`
- `RynBridgeStorage`
- `RynBridgeSecureStorage`
- `RynBridgeUI`

### Android (Gradle)

Add the modules to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation(project(":core"))       // required
    implementation(project(":device"))
    implementation(project(":storage"))
    implementation(project(":secure-storage"))
    implementation(project(":ui"))
}
```

---

## Quick Start

### Web — Initialize the Bridge

```typescript
import { RynBridge, WebViewTransport } from '@rynbridge/core';
import { DeviceModule } from '@rynbridge/device';
import { StorageModule } from '@rynbridge/storage';
import { UIModule } from '@rynbridge/ui';

// Create bridge (WebViewTransport is used by default if omitted)
const bridge = new RynBridge();

// Create module instances
const device = new DeviceModule(bridge);
const storage = new StorageModule(bridge);
const ui = new UIModule(bridge);

// Request-Response
const info = await device.getInfo();
console.log(info.platform, info.model);

// Fire-and-Forget
device.vibrate();
```

### iOS — Set Up WKWebView Bridge

```swift
import WebKit
import RynBridge
import RynBridgeDevice
import RynBridgeStorage
import RynBridgeSecureStorage
import RynBridgeUI

// Create transport with your WKWebView
let transport = WKWebViewTransport(webView: webView)
let bridge = RynBridge(transport: transport)

// Register modules with providers
bridge.register(DeviceModule(provider: DefaultDeviceInfoProvider()))
bridge.register(StorageModule(provider: UserDefaultsStorageProvider()))
bridge.register(SecureStorageModule(provider: KeychainSecureStorageProvider()))
bridge.register(UIModule(provider: DefaultUIProvider()))
```

### Android — Set Up WebView Bridge

```kotlin
import android.webkit.WebView
import io.rynbridge.core.RynBridge
import io.rynbridge.core.WebViewTransport
import io.rynbridge.device.DeviceModule
import io.rynbridge.storage.StorageModule

val webView: WebView = // your WebView

// Create transport and add JS interface
val transport = WebViewTransport(webView)
webView.addJavascriptInterface(transport, "RynBridgeAndroid")

// Create bridge and register modules
val bridge = RynBridge(transport)
bridge.register(DeviceModule(deviceInfoProvider))
bridge.register(StorageModule(storageProvider))
```

---

## Modules

### Device (`@rynbridge/device`)

Provides device information, battery status, screen metrics, and haptic feedback.

```typescript
const device = new DeviceModule(bridge);

// Get device info
const info = await device.getInfo();
// → { platform: "ios", osVersion: "17.0", model: "iPhone", appVersion: "1.0.0" }

// Get battery status
const battery = await device.getBattery();
// → { level: 85, isCharging: true }

// Get screen info
const screen = await device.getScreen();
// → { width: 390, height: 844, scale: 3, orientation: "portrait" }

// Trigger vibration (fire-and-forget)
device.vibrate();
device.vibrate({ pattern: [100, 200, 100] });
```

#### API

| Method | Return Type | Pattern |
|--------|-----------|---------|
| `getInfo()` | `Promise<DeviceInfo>` | Request-Response |
| `getBattery()` | `Promise<BatteryInfo>` | Request-Response |
| `getScreen()` | `Promise<ScreenInfo>` | Request-Response |
| `vibrate(payload?)` | `void` | Fire-and-Forget |

---

### Storage (`@rynbridge/storage`)

Key-value storage backed by UserDefaults (iOS) or SharedPreferences (Android).

```typescript
const storage = new StorageModule(bridge);

await storage.set('username', 'ryn');
const value = await storage.get('username');   // "ryn"
const allKeys = await storage.keys();          // ["username"]
await storage.remove('username');
await storage.clear();
```

#### API

| Method | Return Type |
|--------|-----------|
| `get(key)` | `Promise<string \| null>` |
| `set(key, value)` | `Promise<void>` |
| `remove(key)` | `Promise<void>` |
| `clear()` | `Promise<void>` |
| `keys()` | `Promise<string[]>` |

---

### Secure Storage (`@rynbridge/secure-storage`)

Encrypted key-value storage backed by Keychain (iOS) or KeyStore (Android).

```typescript
const secureStorage = new SecureStorageModule(bridge);

await secureStorage.set('token', 'eyJhbGci...');
const token = await secureStorage.get('token');    // "eyJhbGci..."
const exists = await secureStorage.has('token');   // true
await secureStorage.remove('token');
```

#### API

| Method | Return Type |
|--------|-----------|
| `get(key)` | `Promise<string \| null>` |
| `set(key, value)` | `Promise<void>` |
| `remove(key)` | `Promise<void>` |
| `has(key)` | `Promise<boolean>` |

---

### UI (`@rynbridge/ui`)

Native UI components: alerts, confirms, toasts, and action sheets.

```typescript
const ui = new UIModule(bridge);

// Show alert (waits for dismiss)
await ui.showAlert({ title: 'Hello', message: 'Welcome!' });

// Show confirm dialog
const confirmed = await ui.showConfirm({
  title: 'Delete',
  message: 'Are you sure?',
  confirmText: 'Delete',
  cancelText: 'Cancel',
});
// → true or false

// Show toast (fire-and-forget)
ui.showToast({ message: 'Saved!', duration: 2 });

// Show action sheet
const selectedIndex = await ui.showActionSheet({
  title: 'Choose an option',
  options: ['Edit', 'Share', 'Delete'],
});
// → 0, 1, 2, or -1 (cancelled)
```

#### API

| Method | Return Type | Pattern |
|--------|-----------|---------|
| `showAlert(payload)` | `Promise<void>` | Request-Response |
| `showConfirm(payload)` | `Promise<boolean>` | Request-Response |
| `showToast(payload)` | `void` | Fire-and-Forget |
| `showActionSheet(payload)` | `Promise<number>` | Request-Response |
| `setStatusBar(payload)` | `Promise<void>` | Request-Response |

---

## Architecture

```
┌─────────────────────────────────────────────┐
│                Web (TypeScript)              │
│                                             │
│  @rynbridge/core    @rynbridge/device  ...  │
│        │                   │                │
│        └───────┬───────────┘                │
│                ▼                            │
│        Message Serializer                   │
│                │                            │
└────────────────┼────────────────────────────┘
                 │  JSON over WebView Bridge
┌────────────────┼────────────────────────────┐
│                ▼                            │
│        Message Deserializer                 │
│                │                            │
│        ┌───────┴───────────┐                │
│        │                   │                │
│  RynBridgeCore    RynBridgeDevice     ...   │
│                                             │
│            Native (iOS / Android)           │
└─────────────────────────────────────────────┘
```

### Communication Patterns

| Pattern | Direction | Description |
|---------|-----------|-------------|
| **Request-Response** | Web → Native | Returns a Promise, resolved by native |
| **Event Stream** | Native → Web | Pub/sub event subscription |
| **Fire-and-Forget** | Both | One-way message, no response expected |

### Message Protocol

All communication uses a JSON message format with UUID v4 correlation IDs:

**Request:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "module": "device",
  "action": "getInfo",
  "payload": {},
  "version": "0.1.0"
}
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "success",
  "payload": {
    "platform": "ios",
    "osVersion": "17.0",
    "model": "iPhone",
    "appVersion": "1.0.0"
  },
  "error": null
}
```

### Transport Layer

| Platform | Web → Native | Native → Web |
|----------|-------------|-------------|
| **iOS** | `window.webkit.messageHandlers.RynBridge.postMessage()` | `webView.evaluateJavaScript("window.__rynbridge_receive('...')")` |
| **Android** | `window.RynBridgeAndroid.postMessage()` | `webView.evaluateJavascript("window.__rynbridge_receive('...')")` |

---

## Native Provider Pattern

On iOS and Android, each module delegates to a **Provider** interface. This separates bridge protocol handling from platform implementation, making it easy to swap or mock providers.

### iOS Providers

| Module | Provider Protocol | Default Implementation |
|--------|-------------------|----------------------|
| Device | `DeviceInfoProvider` | `DefaultDeviceInfoProvider` |
| Storage | `StorageProvider` | `UserDefaultsStorageProvider` |
| Secure Storage | `SecureStorageProvider` | `KeychainSecureStorageProvider` |
| UI | `UIProvider` | `DefaultUIProvider` |

```swift
// Use a custom provider
class MyStorageProvider: StorageProvider {
    func get(key: String) -> String? { /* ... */ }
    func set(key: String, value: String) { /* ... */ }
    func remove(key: String) { /* ... */ }
    func clear() { /* ... */ }
    func keys() -> [String] { /* ... */ }
}

bridge.register(StorageModule(provider: MyStorageProvider()))
```

### Android Providers

| Module | Provider Interface | Playground Implementation |
|--------|-------------------|-------------------------|
| Device | `DeviceInfoProvider` | `AndroidDeviceInfoProvider` |
| Storage | `StorageProvider` | `SharedPrefsStorageProvider` |
| Secure Storage | `SecureStorageProvider` | `InMemorySecureStorageProvider` |
| UI | `UIProvider` | `AndroidUIProvider` |

```kotlin
// Use a custom provider
class MyStorageProvider(context: Context) : StorageProvider {
    override fun get(key: String): String? { /* ... */ }
    override fun set(key: String, value: String) { /* ... */ }
    override fun remove(key: String) { /* ... */ }
    override fun clear() { /* ... */ }
    override fun keys(): List<String> { /* ... */ }
}

bridge.register(StorageModule(MyStorageProvider(context)))
```

---

## Error Handling

Bridge errors include a structured error code:

```typescript
import { RynBridgeError, ErrorCode } from '@rynbridge/core';

try {
  await device.getInfo();
} catch (error) {
  if (error instanceof RynBridgeError) {
    console.log(error.code);    // e.g., "TIMEOUT"
    console.log(error.message); // Human-readable message
  }
}
```

| Error Code | Description |
|-----------|-------------|
| `TIMEOUT` | Request timed out (default: 30s) |
| `MODULE_NOT_FOUND` | Module not registered on native side |
| `ACTION_NOT_FOUND` | Action not found in module |
| `INVALID_MESSAGE` | Malformed message |
| `SERIALIZATION_ERROR` | JSON serialization/deserialization failed |
| `TRANSPORT_ERROR` | Transport layer error (e.g., bridge disposed) |
| `VERSION_MISMATCH` | Incompatible version between Web and Native |
| `UNKNOWN` | Unclassified error |

---

## Configuration

```typescript
import { RynBridge } from '@rynbridge/core';

const bridge = new RynBridge({
  timeout: 10_000,    // Request timeout in ms (default: 30000)
  version: '0.1.0',   // Protocol version (default: "0.1.0")
});
```

---

## Playground

The project includes playground apps for E2E testing across all three platforms.

### Build & Run

```bash
# 1. Build the web playground
pnpm install
pnpm build

# 2. Copy web assets to native projects
bash scripts/copy-playground-assets.sh
```

#### iOS

1. Create an Xcode project from the source files in `playground/ios/`
2. Add the `ios/` directory as a local Swift package dependency
3. Run on iOS 17+ Simulator

See [`playground/ios/README.md`](playground/ios/README.md) for detailed setup instructions.

#### Android

```bash
cd android
./gradlew :playground:assembleDebug
```

Install the APK on an API 30+ emulator or device.

### E2E Verification Checklist

| Action | Expected Result |
|--------|---------------|
| `device.getInfo()` | Returns platform, OS version, model |
| `device.getBattery()` | Returns battery level and charging state |
| `device.getScreen()` | Returns screen dimensions and orientation |
| `device.vibrate()` | Triggers haptic feedback |
| `storage.set/get` | Stored value matches retrieved value |
| `storage.keys` | Lists all stored keys |
| `storage.remove/clear` | Removes entries |
| `secureStorage.set/get/has` | Encrypted storage operations |
| `ui.showAlert` | Displays native alert dialog |
| `ui.showConfirm` | Returns `true` or `false` |
| `ui.showToast` | Displays toast message |
| `ui.showActionSheet` | Returns selected index |

---

## Project Structure

```
RynBridge/
├── packages/                     # Web SDK (TypeScript, npm)
│   ├── core/                     # Bridge core
│   ├── device/                   # Device module
│   ├── storage/                  # Storage module
│   ├── secure-storage/           # Secure storage module
│   └── ui/                       # UI module
├── ios/                          # iOS SDK (Swift, SPM)
│   ├── Sources/
│   │   ├── RynBridge/            # Core framework
│   │   ├── RynBridgeDevice/
│   │   ├── RynBridgeStorage/
│   │   ├── RynBridgeSecureStorage/
│   │   └── RynBridgeUI/
│   └── Package.swift
├── android/                      # Android SDK (Kotlin, Gradle)
│   ├── core/
│   ├── device/
│   ├── storage/
│   ├── secure-storage/
│   ├── ui/
│   └── playground/               # Android playground app
├── contracts/                    # JSON Schema definitions (source of truth)
├── playground/
│   ├── web/                      # Web playground (IIFE bundle)
│   └── ios/                      # iOS playground (SwiftUI source files)
└── scripts/
    └── copy-playground-assets.sh
```

## Development

### Prerequisites

- Node.js 20+ (see `.nvmrc`)
- pnpm 9.15+
- Xcode 15+ (for iOS)
- Android Studio + API 30+ SDK (for Android)

### Commands

```bash
pnpm install                          # Install all dependencies
pnpm build                            # Build all packages
pnpm test                             # Run all tests
pnpm lint                             # Lint all packages

# Single package
pnpm --filter @rynbridge/core test
pnpm --filter @rynbridge/core build
```

### Build Pipeline

Managed by [Turborepo](https://turbo.build). Build order respects dependencies:

```
core → device, storage, secure-storage, ui → playground-web
```

---

## Roadmap

| Version | Milestone |
|---------|-----------|
| **v0.1.0** | Core protocol + Phase 1 modules + Playground (current) |
| v0.2.0 | Event Stream pattern, CLI tooling |
| v0.3.0 | DevTools debug panel, documentation site |
| v0.4.0 | Phase 2 modules (auth, push, payment, media, crypto) |
| v1.0.0 | Stable release, Phase 3 modules, performance benchmarks |

### Module Phases

**Phase 1 (v0.1.0):** core, device, storage, secure-storage, ui

**Phase 2 (planned):** auth, push, payment, media, crypto

**Phase 3 (planned):** analytics, navigation, share, health, bluetooth, contacts, calendar, speech, background-task

---

## License

[MIT](LICENSE)
