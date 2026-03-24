# Module API Reference

All modules follow the same pattern: import the module, create an instance, and call methods.

```typescript
const module = new SomeModule();        // Uses RynBridge.shared singleton
const module = new SomeModule(bridge);  // Or inject a custom bridge
```

---

## Device (`@rynbridge/device`)

Device information, battery status, screen metrics, and haptic feedback.

```typescript
const device = new DeviceModule();

const info = await device.getInfo();
// → { platform: "ios", osVersion: "17.0", model: "iPhone", appVersion: "1.0.0" }

const battery = await device.getBattery();
// → { level: 85, isCharging: true }

const screen = await device.getScreen();
// → { width: 390, height: 844, scale: 3, orientation: "portrait" }

device.vibrate();
device.vibrate({ pattern: [100, 200, 100] });
```

| Method | Return Type | Pattern |
|--------|-----------|---------|
| `getInfo()` | `Promise<DeviceInfo>` | Request-Response |
| `getBattery()` | `Promise<BatteryInfo>` | Request-Response |
| `getScreen()` | `Promise<ScreenInfo>` | Request-Response |
| `vibrate(payload?)` | `void` | Fire-and-Forget |

---

## Storage (`@rynbridge/storage`)

Key-value storage backed by UserDefaults (iOS) or SharedPreferences (Android).

```typescript
const storage = new StorageModule();

await storage.set('username', 'ryn');
const value = await storage.get('username');   // "ryn"
const allKeys = await storage.keys();          // ["username"]
await storage.remove('username');
await storage.clear();
```

| Method | Return Type |
|--------|-----------|
| `get(key)` | `Promise<string \| null>` |
| `set(key, value)` | `Promise<void>` |
| `remove(key)` | `Promise<void>` |
| `clear()` | `Promise<void>` |
| `keys()` | `Promise<string[]>` |

---

## Secure Storage (`@rynbridge/secure-storage`)

Encrypted key-value storage backed by Keychain (iOS) or KeyStore (Android).

```typescript
const secureStorage = new SecureStorageModule();

await secureStorage.set('token', 'eyJhbGci...');
const token = await secureStorage.get('token');
const exists = await secureStorage.has('token');   // true
await secureStorage.remove('token');
```

| Method | Return Type |
|--------|-----------|
| `get(key)` | `Promise<string \| null>` |
| `set(key, value)` | `Promise<void>` |
| `remove(key)` | `Promise<void>` |
| `has(key)` | `Promise<boolean>` |

---

## UI (`@rynbridge/ui`)

Native UI components: alerts, confirms, toasts, and action sheets.

```typescript
const ui = new UIModule();

await ui.showAlert({ title: 'Hello', message: 'Welcome!' });

const confirmed = await ui.showConfirm({
  title: 'Delete', message: 'Are you sure?',
  confirmText: 'Delete', cancelText: 'Cancel',
});

ui.showToast({ message: 'Saved!', duration: 2 });

const selectedIndex = await ui.showActionSheet({
  title: 'Choose an option',
  options: ['Edit', 'Share', 'Delete'],
});
```

| Method | Return Type | Pattern |
|--------|-----------|---------|
| `showAlert(payload)` | `Promise<void>` | Request-Response |
| `showConfirm(payload)` | `Promise<boolean>` | Request-Response |
| `showToast(payload)` | `void` | Fire-and-Forget |
| `showActionSheet(payload)` | `Promise<number>` | Request-Response |
| `setStatusBar(payload)` | `Promise<void>` | Request-Response |

---

## Auth (`@rynbridge/auth`)

Authentication with OAuth providers, token management, and auth state observation.

```typescript
const auth = new AuthModule();

const result = await auth.login({ provider: 'google', scopes: ['email'] });
const { token } = await auth.getToken();
const unsub = auth.onAuthStateChange((state) => console.log(state.authenticated));
await auth.logout();
```

---

## Push (`@rynbridge/push`)

Push notification registration, permission management, and notification events.

```typescript
const push = new PushModule();

const { granted } = await push.requestPermission();
const { token } = await push.register();
push.onNotification((n) => console.log(n.title, n.body));
```

---

## Push FCM (`@rynbridge/push-fcm`)

Firebase Cloud Messaging provider.

```typescript
const fcm = new PushFcmModule();

const { token } = await fcm.getToken();
await fcm.deleteToken();
await fcm.subscribeToTopic('news');
await fcm.unsubscribeFromTopic('news');
const { enabled } = await fcm.getAutoInitEnabled();
await fcm.setAutoInitEnabled(false);
fcm.onTokenRefresh(({ token }) => sendTokenToServer(token));
```

| Method | Return Type | Pattern |
|--------|-----------|---------|
| `getToken()` | `Promise<FcmToken>` | Request-Response |
| `deleteToken()` | `Promise<void>` | Request-Response |
| `subscribeToTopic(topic)` | `Promise<void>` | Request-Response |
| `unsubscribeFromTopic(topic)` | `Promise<void>` | Request-Response |
| `getAutoInitEnabled()` | `Promise<FcmAutoInit>` | Request-Response |
| `setAutoInitEnabled(enabled)` | `Promise<void>` | Request-Response |
| `onTokenRefresh(listener)` | `() => void` | Event Stream |

---

## Push APNs (iOS only)

Apple Push Notification service provider.

```typescript
const { token } = await bridge.call('push-apns', 'getToken', {});
await bridge.call('push-apns', 'setBadgeCount', { count: 3 });
const { count } = await bridge.call('push-apns', 'getBadgeCount', {});
await bridge.call('push-apns', 'removeAllDeliveredNotifications', {});
```

---

## Payment (`@rynbridge/payment`)

In-app purchases, product queries, and transaction management.

```typescript
const payment = new PaymentModule();

const { products } = await payment.getProducts({ productIds: ['premium'] });
const receipt = await payment.purchase({ productId: 'premium' });
await payment.finishTransaction({ transactionId: receipt.transactionId });
```

---

## Media (`@rynbridge/media`)

Audio playback, recording, and media picker.

```typescript
const media = new MediaModule();

const { playerId } = await media.playAudio({ source: 'https://example.com/song.mp3' });
const { recordingId } = await media.startRecording({ format: 'm4a' });
const { files } = await media.pickMedia({ type: 'image', multiple: true });
```

---

## Crypto (`@rynbridge/crypto`)

Key generation, key exchange, authenticated encryption (AES-GCM), and key rotation.

```typescript
const crypto = new CryptoModule();

const { publicKey } = await crypto.generateKeyPair();
await crypto.performKeyExchange({ remotePublicKey: '...' });
const encrypted = await crypto.encrypt({ data: 'secret' });
const { plaintext } = await crypto.decrypt(encrypted);
```

---

## Share (`@rynbridge/share`)

Share content via the native share sheet.

```typescript
const share = new ShareModule();

await share.share({ text: 'Check this out!', url: 'https://example.com' });
const { available } = await share.canShare({ url: 'https://example.com' });
```

---

## Contacts (`@rynbridge/contacts`)

Read and write device contacts with permission management.

```typescript
const contacts = new ContactsModule();

const { granted } = await contacts.requestPermission();
const { contacts: list } = await contacts.getContacts({ limit: 50 });
const { contactId } = await contacts.addContact({
  givenName: 'John', familyName: 'Doe', phoneNumbers: ['+1234567890']
});
```

---

## Calendar (`@rynbridge/calendar`)

Create, read, and manage calendar events.

```typescript
const calendar = new CalendarModule();

const { granted } = await calendar.requestPermission();
const { events } = await calendar.getEvents({ startDate: '2025-01-01', endDate: '2025-12-31' });
const { eventId } = await calendar.createEvent({
  title: 'Meeting', startDate: '2025-06-01T10:00:00Z', endDate: '2025-06-01T11:00:00Z'
});
```

---

## Navigation (`@rynbridge/navigation`)

URL opening, deep link handling, and app state observation.

```typescript
const navigation = new NavigationModule();

await navigation.openURL({ url: 'https://example.com' });
const { canOpen } = await navigation.canOpenURL({ url: 'myapp://settings' });
navigation.onDeepLink((link) => console.log(link.url));
navigation.onAppStateChange((state) => console.log(state.state));
```

---

## WebView (`@rynbridge/webview`)

Manage embedded WebView instances and inter-WebView messaging.

```typescript
const webview = new WebViewModule();

const { webviewId } = await webview.open({ url: 'https://example.com', style: 'modal' });
await webview.sendMessage({ targetId: webviewId, data: { action: 'refresh' } });
webview.onMessage((msg) => console.log(msg.data));
await webview.close({ webviewId });
```

---

## Speech (`@rynbridge/speech`)

Speech recognition (STT) and text-to-speech (TTS).

```typescript
const speech = new SpeechModule();

const { granted } = await speech.requestPermission();
const { sessionId } = await speech.startRecognition({ language: 'ko-KR' });
speech.onRecognitionResult((result) => console.log(result.transcript));
await speech.speak({ text: 'Hello, world!', language: 'en-US' });
```

---

## Analytics (`@rynbridge/analytics`)

Event tracking and user property management.

```typescript
const analytics = new AnalyticsModule();

await analytics.logEvent({ name: 'purchase', params: { item: 'premium' } });
await analytics.setUserProperty({ name: 'plan', value: 'pro' });
await analytics.setUserId({ userId: 'user_123' });
```

---

## Translation (`@rynbridge/translation`)

Text translation and language detection.

```typescript
const translation = new TranslationModule();

const { translatedText } = await translation.translate({
  text: '안녕하세요', sourceLanguage: 'ko', targetLanguage: 'en'
});
const { language, confidence } = await translation.detectLanguage({ text: 'Hello' });
const { languages } = await translation.getSupportedLanguages();
```

---

## Bluetooth (`@rynbridge/bluetooth`)

Bluetooth Low Energy (BLE) device scanning, connection, and characteristic read/write.

```typescript
const bluetooth = new BluetoothModule();

const { granted } = await bluetooth.requestPermission();
const { state } = await bluetooth.getState();

await bluetooth.startScan({ serviceUUIDs: ['180D'] });
bluetooth.onDeviceFound((device) => console.log(device.name, device.rssi));

const { success } = await bluetooth.connect({ deviceId: 'ABC-123' });
const { services } = await bluetooth.getServices({ deviceId: 'ABC-123' });
const { value } = await bluetooth.readCharacteristic({
  deviceId: 'ABC-123', serviceUUID: '180D', characteristicUUID: '2A37'
});
await bluetooth.disconnect({ deviceId: 'ABC-123' });
```

---

## Health (`@rynbridge/health`)

Health data access via HealthKit (iOS) or Health Connect (Android).

```typescript
const health = new HealthModule();

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
```

---

## Background Task (`@rynbridge/background-task`)

Schedule and manage background tasks (BGTaskScheduler on iOS, WorkManager on Android).

```typescript
const bgTask = new BackgroundTaskModule();

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

---

## Kakao Share (`@rynbridge/share-kakao`)

Share content via KakaoTalk using Kakao SDK templates.

```typescript
const kakaoShare = new KakaoShareModule();

const { available } = await kakaoShare.isAvailable();

await kakaoShare.shareFeed({
  content: {
    title: 'Check this out!',
    imageUrl: 'https://example.com/image.jpg',
    link: { webUrl: 'https://example.com' }
  },
  buttons: [{ title: 'Open', link: { webUrl: 'https://example.com' } }]
});

await kakaoShare.shareCommerce({
  content: { title: 'Product', imageUrl: '...', link: { webUrl: '...' } },
  commerce: { regularPrice: 10000, discountPrice: 8000 }
});

await kakaoShare.shareList({ headerTitle: 'Top Items', headerLink: {}, contents: [...] });
await kakaoShare.shareCustom({ templateId: 12345, templateArgs: { key: 'value' } });
```

---

## DevTools (`@rynbridge/devtools`)

In-app debug panel for inspecting bridge messages in real-time.

```typescript
import { DevToolsTransport, DevToolsPanel } from '@rynbridge/devtools';

const devtools = new DevToolsTransport(new WebViewTransport());
const bridge = new RynBridge({}, devtools);
DevToolsPanel.attach(devtools.store);
```

Features: message timeline, payload inspector, filters, statistics.

For production, use dynamic import:

```typescript
if (process.env.NODE_ENV === 'development') {
  const { DevToolsTransport, DevToolsPanel } = await import('@rynbridge/devtools');
  transport = new DevToolsTransport(transport);
  DevToolsPanel.attach(transport.store);
}
```
