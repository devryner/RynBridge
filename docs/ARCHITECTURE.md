# Architecture

## Overview

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

## Communication Patterns

| Pattern | Direction | Description |
|---------|-----------|-------------|
| **Request-Response** | Web → Native | Returns a Promise, resolved by native |
| **Event Stream** | Native → Web | Pub/sub event subscription |
| **Fire-and-Forget** | Both | One-way message, no response expected |

## Message Protocol

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

## Transport Layer

| Platform | Web → Native | Native → Web |
|----------|-------------|-------------|
| **iOS** | `window.webkit.messageHandlers.RynBridge.postMessage()` | `webView.evaluateJavaScript("window.__rynbridge_receive('...')")` |
| **Android** | `window.RynBridgeAndroid.postMessage()` | `webView.evaluateJavascript("window.__rynbridge_receive('...')")` |

## Core Internal Components

- **RynBridge** — Main facade. Orchestrates all components. Accepts a `Transport` and `BridgeConfig`.
- **Transport** — Interface with `send()`, `onMessage()`, `dispose()`.
  - `WebViewTransport` — Production transport for iOS/Android WebView.
  - `MockTransport` — For testing. Records messages and provides `simulateIncoming()`.
- **MessageSerializer / MessageDeserializer** — JSON encode/decode with UUID generation.
- **CallbackRegistry** — Maps request IDs to pending Promises with timeout support.
- **EventEmitter** — Pub/sub for native-to-web event streams (`module:action` pattern).
- **ModuleRegistry** — Registers `BridgeModule` objects and routes incoming requests.
- **VersionNegotiator** — Semantic version comparison for compatibility checks.

## Native Provider Pattern

On iOS and Android, each module delegates to a **Provider** interface. This separates bridge protocol handling from platform implementation, making it easy to swap or mock providers.

### iOS Providers

| Module | Provider Protocol | Default Implementation |
|--------|-------------------|----------------------|
| Device | `DeviceInfoProvider` | `DefaultDeviceInfoProvider` |
| Storage | `StorageProvider` | `DefaultStorageProvider` |
| Secure Storage | `SecureStorageProvider` | `DefaultSecureStorageProvider` |
| UI | `UIProvider` | `DefaultUIProvider` |
| Auth | `AuthProvider` | — (sub-packages: `RynBridgeAuthApple`) |
| Push | `PushProvider` | `DefaultAPNsPushProvider` (via `RynBridgePushAPNs`) |
| Payment | `PaymentProvider` | — (sub-packages: `RynBridgePaymentStoreKit`) |
| Media | `MediaProvider` | `DefaultMediaProvider` |
| Crypto | `CryptoProvider` | `DefaultCryptoProvider` |
| Share | `ShareProvider` | `DefaultShareProvider` |
| Contacts | `ContactsProvider` | `DefaultContactsProvider` |
| Calendar | `CalendarProvider` | `DefaultCalendarProvider` |
| Navigation | `NavigationProvider` | `DefaultNavigationProvider` |
| WebView | `WebViewProvider` | `DefaultWebViewProvider` |
| Speech | `SpeechProvider` | `DefaultSpeechProvider` |
| Analytics | `AnalyticsProvider` | `DefaultAnalyticsProvider` |
| Translation | `TranslationProvider` | `DefaultTranslationProvider` |
| Bluetooth | `BluetoothProvider` | `DefaultBluetoothProvider` |
| Health | `HealthProvider` | `DefaultHealthProvider` |
| Background Task | `BackgroundTaskProvider` | `DefaultBackgroundTaskProvider` |
| Push APNs | `APNsPushProvider` | `DefaultAPNsPushProvider` |
| Push FCM | `FCMPushProvider` | `FirebaseFCMPushProvider` (requires Firebase) |
| Kakao Share | `KakaoShareProvider` | `KakaoShareModule` (requires KakaoSDK) |

```swift
// Custom provider example
bridge.register(StorageModule(provider: MyCustomStorageProvider()))
```

### Android Providers

| Module | Provider Interface | Default Implementation |
|--------|-------------------|----------------------|
| Device | `DeviceInfoProvider` | `DefaultDeviceInfoProvider` |
| Storage | `StorageProvider` | `DefaultStorageProvider` |
| Secure Storage | `SecureStorageProvider` | `DefaultSecureStorageProvider` |
| UI | `UIProvider` | `DefaultUIProvider` |
| Auth | `AuthProvider` | — (sub-packages: `auth-google`, `auth-kakao`) |
| Push | `PushProvider` | — (sub-packages: `push-fcm`) |
| Payment | `PaymentProvider` | — (sub-packages: `payment-google-play`) |
| Media | `MediaProvider` | `DefaultMediaProvider` |
| Crypto | `CryptoProvider` | `DefaultCryptoProvider` |
| Share | `ShareProvider` | `DefaultShareProvider` |
| Contacts | `ContactsProvider` | `DefaultContactsProvider` |
| Calendar | `CalendarProvider` | `DefaultCalendarProvider` |
| Navigation | `NavigationProvider` | `DefaultNavigationProvider` |
| WebView | `WebViewProvider` | `DefaultWebViewProvider` |
| Speech | `SpeechProvider` | `DefaultSpeechProvider` |
| Analytics | `AnalyticsProvider` | `DefaultAnalyticsProvider` |
| Translation | `TranslationProvider` | `DefaultTranslationProvider` |
| Bluetooth | `BluetoothProvider` | `DefaultBluetoothProvider` |
| Health | `HealthProvider` | `DefaultHealthProvider` |
| Background Task | `BackgroundTaskProvider` | `DefaultBackgroundTaskProvider` |
| Push FCM | `PushFCMProvider` | `FirebasePushFCMProvider` (requires Firebase) |
| Kakao Share | `KakaoShareProvider` | `DefaultKakaoShareProvider` (requires KakaoSDK) |

```kotlin
// Custom provider example
bridge.register(StorageModule(MyCustomStorageProvider(context)))
```

## Permission Handling

### Android Permissions

| Module | Required Permissions | Checked At |
|--------|---------------------|------------|
| Device | `VIBRATE` | Declared in manifest (auto-granted) |
| Bluetooth | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` | Before scan/connect/read/write operations |
| Contacts | `READ_CONTACTS`, `WRITE_CONTACTS` | Before read/write operations respectively |
| Calendar | `READ_CALENDAR`, `WRITE_CALENDAR` | Before read/write operations respectively |
| Health | Health Connect permissions | Checked via `getPermissionStatus()` |

### iOS Permissions

| Module | Required Permission | Behavior |
|--------|-------------------|----------|
| Device (Camera) | Camera (`NSCameraUsageDescription`) | Auto-requests if undetermined |
| Device (Location) | Location (`NSLocationWhenInUseUsageDescription`) | Auto-requests if undetermined |
| Media (Recording) | Microphone (`NSMicrophoneUsageDescription`) | Auto-requests if undetermined |
| Health | HealthKit (`NSHealthShareUsageDescription`) | Uses `HKHealthStore.requestAuthorization` |
| Bluetooth | Bluetooth (`NSBluetoothAlwaysUsageDescription`) | Checks `CBCentralManager.authorization` |
| Speech | Speech Recognition (`NSSpeechRecognitionUsageDescription`) | Checks `SFSpeechRecognizer.authorizationStatus` |
| Calendar | Calendar (`NSCalendarsFullAccessUsageDescription`) | Uses `EKEventStore.requestFullAccessToEvents` |

> **Note:** Some Android default provider methods (e.g., `capturePhoto`, `getLocation`, `authenticate`) require an Activity context and throw `RynBridgeError`. Use a custom provider with Activity-based integration for these features.

## Project Structure

```
RynBridge/
├── packages/                     # Web SDK (TypeScript, npm)
│   ├── core/                     # Bridge core
│   ├── device/                   # Device module
│   ├── storage/                  # Storage module
│   ├── ...                       # (26 module packages total)
│   ├── cli/                      # CLI tool
│   ├── codegen/                  # Schema → code generator
│   └── devtools/                 # In-app debug panel
├── ios/                          # iOS SDK (Swift, SPM)
│   ├── Sources/
│   │   ├── RynBridge/            # Core framework
│   │   ├── RynBridgeDevice/      # ...and 25 more module targets
│   │   └── ...
│   └── Package.swift
├── android/                      # Android SDK (Kotlin, Gradle)
│   ├── core/
│   ├── device/                   # ...and 26 more module directories
│   ├── ...
│   └── playground/               # Android playground app
├── contracts/                    # JSON Schema definitions (source of truth)
├── docs/                         # Docusaurus documentation site
└── playground/                   # Web & iOS playground apps
```
