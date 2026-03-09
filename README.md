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

# Phase 2 modules
npm install @rynbridge/auth
npm install @rynbridge/push
npm install @rynbridge/payment
npm install @rynbridge/media
npm install @rynbridge/crypto

# Phase 3 modules
npm install @rynbridge/share
npm install @rynbridge/contacts
npm install @rynbridge/calendar
npm install @rynbridge/navigation
npm install @rynbridge/webview
npm install @rynbridge/speech
npm install @rynbridge/analytics
npm install @rynbridge/translation
npm install @rynbridge/bluetooth
npm install @rynbridge/health
npm install @rynbridge/background-task

# Platform-specific modules
npm install @rynbridge/share-kakao
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
- `RynBridgeAuth`
- `RynBridgePush`
- `RynBridgePayment`
- `RynBridgeMedia`
- `RynBridgeCrypto`
- `RynBridgeShare`
- `RynBridgeContacts`
- `RynBridgeCalendar`
- `RynBridgeNavigation`
- `RynBridgeWebView`
- `RynBridgeSpeech`
- `RynBridgeAnalytics`
- `RynBridgeTranslation`
- `RynBridgeBluetooth`
- `RynBridgeHealth`
- `RynBridgeBackgroundTask`
- `RynBridgeShareKakao` (requires KakaoSDK)

### Android (Gradle)

Add the modules to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation(project(":core"))       // required
    implementation(project(":device"))
    implementation(project(":storage"))
    implementation(project(":secure-storage"))
    implementation(project(":ui"))
    implementation(project(":auth"))
    implementation(project(":push"))
    implementation(project(":payment"))
    implementation(project(":media"))
    implementation(project(":crypto"))

    // Phase 3 modules
    implementation(project(":share"))
    implementation(project(":contacts"))
    implementation(project(":calendar"))
    implementation(project(":navigation"))
    implementation(project(":webview"))
    implementation(project(":speech"))
    implementation(project(":analytics"))
    implementation(project(":translation"))
    implementation(project(":bluetooth"))
    implementation(project(":health"))
    implementation(project(":background-task"))
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

### Auth (`@rynbridge/auth`)

Authentication with OAuth providers, token management, and auth state observation.

```typescript
const auth = new AuthModule(bridge);

const result = await auth.login({ provider: 'google', scopes: ['email'] });
const { token } = await auth.getToken();
const unsub = auth.onAuthStateChange((state) => console.log(state.authenticated));
await auth.logout();
```

### Push (`@rynbridge/push`)

Push notification registration, permission management, and notification events.

```typescript
const push = new PushModule(bridge);

const { granted } = await push.requestPermission();
const { token } = await push.register();
push.onNotification((n) => console.log(n.title, n.body));
```

### Payment (`@rynbridge/payment`)

In-app purchases, product queries, and transaction management.

```typescript
const payment = new PaymentModule(bridge);

const { products } = await payment.getProducts({ productIds: ['premium'] });
const receipt = await payment.purchase({ productId: 'premium' });
await payment.finishTransaction({ transactionId: receipt.transactionId });
```

### Media (`@rynbridge/media`)

Audio playback, recording, and media picker.

```typescript
const media = new MediaModule(bridge);

const { playerId } = await media.playAudio({ source: 'https://example.com/song.mp3' });
const { recordingId } = await media.startRecording({ format: 'm4a' });
const { files } = await media.pickMedia({ type: 'image', multiple: true });
```

### Crypto (`@rynbridge/crypto`)

Key generation, key exchange, authenticated encryption (AES-GCM), and key rotation.

```typescript
const crypto = new CryptoModule(bridge);

const { publicKey } = await crypto.generateKeyPair();
await crypto.performKeyExchange({ remotePublicKey: '...' });
const encrypted = await crypto.encrypt({ data: 'secret' });
const { plaintext } = await crypto.decrypt(encrypted);
```

### Share (`@rynbridge/share`)

Share content via the native share sheet.

```typescript
const share = new ShareModule(bridge);

await share.share({ text: 'Check this out!', url: 'https://example.com' });
const { available } = await share.canShare({ url: 'https://example.com' });
```

### Contacts (`@rynbridge/contacts`)

Read and write device contacts with permission management.

```typescript
const contacts = new ContactsModule(bridge);

const { granted } = await contacts.requestPermission();
const { contacts: list } = await contacts.getContacts({ limit: 50 });
const { contactId } = await contacts.addContact({
  givenName: 'John', familyName: 'Doe', phoneNumbers: ['+1234567890']
});
```

### Calendar (`@rynbridge/calendar`)

Create, read, and manage calendar events.

```typescript
const calendar = new CalendarModule(bridge);

const { granted } = await calendar.requestPermission();
const { events } = await calendar.getEvents({ startDate: '2025-01-01', endDate: '2025-12-31' });
const { eventId } = await calendar.createEvent({
  title: 'Meeting', startDate: '2025-06-01T10:00:00Z', endDate: '2025-06-01T11:00:00Z'
});
```

### Navigation (`@rynbridge/navigation`)

URL opening, deep link handling, and app state observation.

```typescript
const navigation = new NavigationModule(bridge);

await navigation.openURL({ url: 'https://example.com' });
const { canOpen } = await navigation.canOpenURL({ url: 'myapp://settings' });
navigation.onDeepLink((link) => console.log(link.url));
navigation.onAppStateChange((state) => console.log(state.state));
```

### WebView (`@rynbridge/webview`)

Manage embedded WebView instances and inter-WebView messaging.

```typescript
const webview = new WebViewModule(bridge);

const { webviewId } = await webview.open({ url: 'https://example.com', style: 'modal' });
await webview.sendMessage({ targetId: webviewId, data: { action: 'refresh' } });
webview.onMessage((msg) => console.log(msg.data));
await webview.close({ webviewId });
```

### Speech (`@rynbridge/speech`)

Speech recognition (STT) and text-to-speech (TTS).

```typescript
const speech = new SpeechModule(bridge);

const { granted } = await speech.requestPermission();
const { sessionId } = await speech.startRecognition({ language: 'ko-KR' });
speech.onRecognitionResult((result) => console.log(result.transcript));
await speech.speak({ text: 'Hello, world!', language: 'en-US' });
```

### Analytics (`@rynbridge/analytics`)

Event tracking and user property management. Interface-only — requires a provider sub-package (e.g., `analytics-firebase`).

```typescript
const analytics = new AnalyticsModule(bridge);

await analytics.logEvent({ name: 'purchase', params: { item: 'premium' } });
await analytics.setUserProperty({ name: 'plan', value: 'pro' });
await analytics.setUserId({ userId: 'user_123' });
```

### Translation (`@rynbridge/translation`)

Text translation and language detection. Interface-only — requires a provider sub-package (e.g., `translation-apple`, `translation-mlkit`).

```typescript
const translation = new TranslationModule(bridge);

const { translatedText } = await translation.translate({
  text: '안녕하세요', sourceLanguage: 'ko', targetLanguage: 'en'
});
const { language, confidence } = await translation.detectLanguage({ text: 'Hello' });
const { languages } = await translation.getSupportedLanguages();
```

### Bluetooth (`@rynbridge/bluetooth`)

Bluetooth Low Energy (BLE) device scanning, connection, and characteristic read/write.

```typescript
const bluetooth = new BluetoothModule(bridge);

const { granted } = await bluetooth.requestPermission();
const { state } = await bluetooth.getState();
// → { state: 'poweredOn' }

await bluetooth.startScan({ serviceUUIDs: ['180D'] });
bluetooth.onDeviceFound((device) => console.log(device.name, device.rssi));

const { success } = await bluetooth.connect({ deviceId: 'ABC-123' });
const { services } = await bluetooth.getServices({ deviceId: 'ABC-123' });
const { value } = await bluetooth.readCharacteristic({
  deviceId: 'ABC-123', serviceUUID: '180D', characteristicUUID: '2A37'
});
bluetooth.onCharacteristicChange((change) => console.log(change.value));
await bluetooth.disconnect({ deviceId: 'ABC-123' });
```

### Health (`@rynbridge/health`)

Health data access via HealthKit (iOS) or Health Connect (Android).

```typescript
const health = new HealthModule(bridge);

const { available } = await health.isAvailable();
const { granted } = await health.requestPermission({
  readTypes: ['stepCount', 'heartRate'], writeTypes: ['stepCount']
});

const { steps } = await health.getSteps({ startDate: '2025-01-01', endDate: '2025-01-31' });
const { records } = await health.queryData({
  dataType: 'heartRate', startDate: '2025-01-01', endDate: '2025-01-31'
});
await health.writeData({
  dataType: 'stepCount', value: 1000, unit: 'count',
  startDate: '2025-01-01T00:00:00Z', endDate: '2025-01-01T23:59:59Z'
});
health.onDataChange((event) => console.log(event.dataType));
```

### Background Task (`@rynbridge/background-task`)

Schedule and manage background tasks (BGTaskScheduler on iOS, WorkManager on Android).

```typescript
const bgTask = new BackgroundTaskModule(bridge);

const { granted } = await bgTask.requestPermission();
const { taskId, success } = await bgTask.scheduleTask({
  taskId: 'sync-data', type: 'periodic', interval: 3600,
  requiresNetwork: true, requiresCharging: false
});

const { tasks } = await bgTask.getScheduledTasks();
bgTask.onTaskExecute((event) => {
  console.log('Executing:', event.taskId);
  bgTask.completeTask({ taskId: event.taskId, success: true });
});

await bgTask.cancelTask({ taskId: 'sync-data' });
await bgTask.cancelAllTasks();
```

### Kakao Share (`@rynbridge/share-kakao`)

Share content via KakaoTalk using Kakao SDK templates.

```typescript
const kakaoShare = new KakaoShareModule(bridge);

const { available } = await kakaoShare.isAvailable();

// Feed template
await kakaoShare.shareFeed({
  content: {
    title: 'Check this out!',
    imageUrl: 'https://example.com/image.jpg',
    link: { webUrl: 'https://example.com' }
  },
  buttons: [{ title: 'Open', link: { webUrl: 'https://example.com' } }]
});

// Commerce template
await kakaoShare.shareCommerce({
  content: { title: 'Product', imageUrl: '...', link: { webUrl: '...' } },
  commerce: { regularPrice: 10000, discountPrice: 8000 }
});

// List & Custom templates
await kakaoShare.shareList({ headerTitle: 'Top Items', headerLink: {}, contents: [...] });
await kakaoShare.shareCustom({ templateId: 12345, templateArgs: { key: 'value' } });
```

> For a complete integration walkthrough with native provider implementations, see the **[Integration Guide](docs/docs/guides/integration.md)**.

---

## DevTools

`@rynbridge/devtools` provides an in-app debug panel for inspecting bridge messages in real-time.

```bash
npm install @rynbridge/devtools
```

```typescript
import { RynBridge, WebViewTransport } from '@rynbridge/core';
import { DevToolsTransport, DevToolsPanel } from '@rynbridge/devtools';

const devtools = new DevToolsTransport(new WebViewTransport());
const bridge = new RynBridge({}, devtools);

// Attach visual panel (renders at bottom of WebView)
DevToolsPanel.attach(devtools.store);
```

- **Message timeline** — Direction, module.action, status badge, latency
- **Payload inspector** — Click to expand request/response JSON
- **Filters** — Filter by module, direction, status
- **Statistics** — Total message count, average latency

For production, use dynamic import to exclude DevTools from the bundle:

```typescript
if (process.env.NODE_ENV === 'development') {
  const { DevToolsTransport, DevToolsPanel } = await import('@rynbridge/devtools');
  transport = new DevToolsTransport(transport);
  DevToolsPanel.attach(transport.store);
}
```

> See the full [DevTools documentation](docs/docs/devtools/overview.md) for details.

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
| Auth | `AuthProvider` | — (sub-packages: `RynBridgeAuthApple`) |
| Push | `PushProvider` | — (sub-packages: `RynBridgePushAPNS`) |
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
| Kakao Share | — | `RynBridgeShareKakao` (requires KakaoSDK) |

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

| Module | Provider Interface | Default/Playground Implementation |
|--------|-------------------|----------------------------------|
| Device | `DeviceInfoProvider` | `AndroidDeviceInfoProvider` |
| Storage | `StorageProvider` | `SharedPrefsStorageProvider` |
| Secure Storage | `SecureStorageProvider` | `InMemorySecureStorageProvider` |
| UI | `UIProvider` | `AndroidUIProvider` |
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
| Analytics | `AnalyticsProvider` | — (interface only) |
| Translation | `TranslationProvider` | — (interface only) |
| Bluetooth | `BluetoothProvider` | `DefaultBluetoothProvider` |
| Health | `HealthProvider` | `DefaultHealthProvider` |
| Background Task | `BackgroundTaskProvider` | `DefaultBackgroundTaskProvider` |

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
│   ├── ui/                       # UI module
│   ├── auth/                     # Auth module
│   ├── push/                     # Push notification module
│   ├── payment/                  # In-app payment module
│   ├── media/                    # Media playback/recording module
│   ├── crypto/                   # Cryptographic operations module
│   ├── share/                    # Share sheet module
│   ├── contacts/                 # Contacts module
│   ├── calendar/                 # Calendar module
│   ├── navigation/               # Navigation & deep link module
│   ├── webview/                  # WebView management module
│   ├── speech/                   # Speech recognition & TTS module
│   ├── analytics/                # Analytics module
│   ├── translation/              # Translation module
│   ├── bluetooth/                # Bluetooth BLE module
│   ├── health/                   # Health data module
│   ├── background-task/          # Background task module
│   ├── share-kakao/              # Kakao Talk share module
│   ├── cli/                      # CLI tool (init, add, generate, doctor)
│   ├── codegen/                  # Schema → TypeScript/Swift/Kotlin code generator
│   └── devtools/                 # In-app debug panel
├── ios/                          # iOS SDK (Swift, SPM)
│   ├── Sources/
│   │   ├── RynBridge/            # Core framework
│   │   ├── RynBridgeDevice/
│   │   ├── RynBridgeStorage/
│   │   ├── RynBridgeSecureStorage/
│   │   ├── RynBridgeUI/
│   │   ├── RynBridgeAuth/
│   │   ├── RynBridgePush/
│   │   ├── RynBridgePayment/
│   │   ├── RynBridgeMedia/
│   │   ├── RynBridgeCrypto/
│   │   ├── RynBridgeShare/
│   │   ├── RynBridgeContacts/
│   │   ├── RynBridgeCalendar/
│   │   ├── RynBridgeNavigation/
│   │   ├── RynBridgeWebView/
│   │   ├── RynBridgeSpeech/
│   │   ├── RynBridgeAnalytics/
│   │   ├── RynBridgeTranslation/
│   │   ├── RynBridgeBluetooth/
│   │   ├── RynBridgeHealth/
│   │   ├── RynBridgeBackgroundTask/
│   │   ├── RynBridgeShareKakao/
│   │   ├── RynBridgeAuthApple/
│   │   ├── RynBridgeAuthKakao/
│   │   ├── RynBridgePushAPNs/
│   │   └── RynBridgePaymentStoreKit/
│   └── Package.swift
├── android/                      # Android SDK (Kotlin, Gradle)
│   ├── core/
│   ├── device/
│   ├── storage/
│   ├── secure-storage/
│   ├── ui/
│   ├── auth/
│   ├── push/
│   ├── payment/
│   ├── media/
│   ├── crypto/
│   ├── share/
│   ├── contacts/
│   ├── calendar/
│   ├── navigation/
│   ├── webview/
│   ├── speech/
│   ├── analytics/
│   ├── translation/
│   ├── bluetooth/
│   ├── health/
│   ├── background-task/
│   ├── auth-google/              # Google Sign-In provider
│   ├── auth-kakao/               # Kakao login provider
│   ├── push-fcm/                 # Firebase Cloud Messaging provider
│   ├── payment-google-play/      # Google Play Billing provider
│   └── playground/               # Android playground app
├── contracts/                    # JSON Schema definitions (source of truth)
├── docs/                         # Docusaurus documentation site
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
core → device, storage, secure-storage, ui, auth, push, payment, media, crypto,
       share, contacts, calendar, navigation, webview, speech, analytics, translation,
       bluetooth, health, background-task, share-kakao → playground-web
```

---

## Roadmap

| Version | Milestone | Status |
|---------|-----------|--------|
| **v0.0.1** | Core protocol, 3-platform SDKs, Playground | ✅ Done |
| **v0.0.2** | Phase 1 modules (device, storage, secure-storage, ui) | ✅ Done |
| **v0.0.3** | DX tools — CLI, codegen, DevTools, docs site | ✅ Done |
| **v0.0.4** | Phase 2 modules (auth, push, payment, media, crypto) | ✅ Done |
| **v0.0.5** | Native providers — crypto, media + auth/push/payment sub-packages | ✅ Done |
| **v0.0.6** | Phase 3 basic — share, contacts, calendar | ✅ Done |
| **v0.0.7** | Phase 3 intermediate — navigation, webview, speech, analytics, translation | ✅ Done |
| **v0.0.8** | Phase 3 advanced — bluetooth, health, background-task | ✅ Done |
| **v0.0.9** | Release pipeline — npm publish, SPM release, Maven Central | ✅ Done |
| **v0.1.0** | Full module unit tests (3-platform CI integration) | ✅ Done |
| **v0.1.1** | CLI doctor enhancement (dependency, permission, schema validation) | ✅ Done |
| **v0.1.2** | API stabilization, performance benchmarks, bundle size CI | ✅ Done |
| **v0.1.3** | Native → Web event emission (`emitEvent` API) | ✅ Done |
| **v0.1.4** | 3rd-party sub-modules — Kakao Share (Web + iOS) | ✅ Done |
| **v0.2.0** | Package publishing — npm, SPM release, Maven Central | 🔲 Next |
| **v0.3.0** | Stable release + open source governance | 🔲 Planned |

### Module Phases

**Phase 1:** core, device, storage, secure-storage, ui

**Phase 2:** auth, push, payment, media, crypto

**Phase 3:** share, contacts, calendar, navigation, webview, speech, analytics, translation, bluetooth, health, background-task

**Platform-specific:** share-kakao

---

## License

[MIT](LICENSE)
