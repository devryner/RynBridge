---
sidebar_position: 1
---

# Integration Guide

Step-by-step guide to integrating RynBridge Phase 2 modules (auth, push, payment, media, crypto) into a real hybrid app.

## Prerequisites

- RynBridge core set up on all three platforms (see [Quick Start](../getting-started/quick-start.md))
- A working WebView-based hybrid app with Web ↔ Native bridge communication

---

## 1. Install Phase 2 Modules

### Web

```bash
npm install @rynbridge/auth @rynbridge/push @rynbridge/payment @rynbridge/media @rynbridge/crypto
```

### iOS (Package.swift)

Add the products you need:

```swift
dependencies: [
    .package(url: "https://github.com/devryner/RynBridge.git", from: "0.1.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "RynBridge", package: "RynBridge"),
            .product(name: "RynBridgeAuth", package: "RynBridge"),
            .product(name: "RynBridgePush", package: "RynBridge"),
            .product(name: "RynBridgePayment", package: "RynBridge"),
            .product(name: "RynBridgeMedia", package: "RynBridge"),
            .product(name: "RynBridgeCrypto", package: "RynBridge"),
        ]
    )
]
```

### Android (build.gradle.kts)

```kotlin
dependencies {
    implementation(project(":core"))
    implementation(project(":auth"))
    implementation(project(":push"))
    implementation(project(":payment"))
    implementation(project(":media"))
    implementation(project(":crypto"))
}
```

---

## 2. Web SDK — Initialize Modules

```typescript
import { RynBridge } from '@rynbridge/core';
import { AuthModule } from '@rynbridge/auth';
import { PushModule } from '@rynbridge/push';
import { PaymentModule } from '@rynbridge/payment';
import { MediaModule } from '@rynbridge/media';
import { CryptoModule } from '@rynbridge/crypto';

const bridge = new RynBridge();

const auth = new AuthModule(bridge);
const push = new PushModule(bridge);
const payment = new PaymentModule(bridge);
const media = new MediaModule(bridge);
const crypto = new CryptoModule(bridge);
```

---

## 3. Implement Native Providers

Each module requires a **Provider** implementation on the native side. The provider is a protocol (iOS) or interface (Android) that you implement with your app's business logic.

### Auth

<details>
<summary>iOS — AuthProvider</summary>

```swift
import RynBridgeAuth

class MyAuthProvider: AuthProvider {
    func login(provider: String, scopes: [String]) async throws -> LoginResult {
        // Call your OAuth SDK (e.g., Google Sign-In, Apple Sign-In)
        let token = try await OAuthService.login(provider: provider, scopes: scopes)
        return LoginResult(
            token: token.accessToken,
            refreshToken: token.refreshToken,
            expiresAt: token.expiresAt.iso8601,
            user: AuthUser(id: token.userId, email: token.email, name: token.name, profileImage: nil)
        )
    }

    func logout() async throws {
        try await OAuthService.logout()
    }

    func getToken() async throws -> TokenResult {
        guard let token = TokenStore.current else {
            return TokenResult(token: nil, expiresAt: nil)
        }
        return TokenResult(token: token.accessToken, expiresAt: token.expiresAt.iso8601)
    }

    func refreshToken() async throws -> LoginResult {
        let token = try await OAuthService.refresh()
        return LoginResult(token: token.accessToken, refreshToken: token.refreshToken, expiresAt: token.expiresAt.iso8601)
    }

    func getUser() async throws -> AuthUser? {
        guard let user = UserStore.current else { return nil }
        return AuthUser(id: user.id, email: user.email, name: user.name, profileImage: user.avatarURL)
    }
}
```

</details>

<details>
<summary>Android — AuthProvider</summary>

```kotlin
import io.rynbridge.auth.*

class MyAuthProvider(private val context: Context) : AuthProvider {
    override suspend fun login(provider: String, scopes: List<String>): LoginResult {
        val token = OAuthService.login(context, provider, scopes)
        return LoginResult(
            token = token.accessToken,
            refreshToken = token.refreshToken,
            expiresAt = token.expiresAt,
            user = AuthUser(id = token.userId, email = token.email, name = token.name, profileImage = null)
        )
    }

    override suspend fun logout() {
        OAuthService.logout(context)
    }

    override suspend fun getToken(): TokenResult {
        val token = TokenStore.getCurrent(context)
        return TokenResult(token = token?.accessToken, expiresAt = token?.expiresAt)
    }

    override suspend fun refreshToken(): LoginResult {
        val token = OAuthService.refresh(context)
        return LoginResult(token = token.accessToken, refreshToken = token.refreshToken, expiresAt = token.expiresAt)
    }

    override suspend fun getUser(): AuthUser? {
        val user = UserStore.getCurrent(context) ?: return null
        return AuthUser(id = user.id, email = user.email, name = user.name, profileImage = user.avatarUrl)
    }
}
```

</details>

### Push

<details>
<summary>iOS — PushProvider</summary>

```swift
import RynBridgePush
import UserNotifications

class MyPushProvider: PushProvider {
    func register() async throws -> PushRegistration {
        let token = try await APNSService.registerForRemoteNotifications()
        return PushRegistration(token: token, platform: "ios")
    }

    func unregister() async throws {
        await UIApplication.shared.unregisterForRemoteNotifications()
    }

    func getToken() async throws -> String? {
        APNSService.currentToken
    }

    func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        return granted
    }

    func getPermissionStatus() async throws -> PushPermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status: String
        switch settings.authorizationStatus {
        case .authorized: status = "granted"
        case .denied: status = "denied"
        default: status = "notDetermined"
        }
        return PushPermissionStatus(status: status)
    }
}
```

</details>

<details>
<summary>Android — PushProvider</summary>

```kotlin
import io.rynbridge.push.*

class MyPushProvider(private val context: Context) : PushProvider {
    override suspend fun register(): PushRegistration {
        val token = FirebaseMessaging.getInstance().token.await()
        return PushRegistration(token = token, platform = "android")
    }

    override suspend fun unregister() {
        FirebaseMessaging.getInstance().deleteToken().await()
    }

    override suspend fun getToken(): String? {
        return try { FirebaseMessaging.getInstance().token.await() } catch (e: Exception) { null }
    }

    override suspend fun requestPermission(): Boolean {
        // Android 13+ runtime permission
        return PermissionHelper.requestNotificationPermission(context)
    }

    override suspend fun getPermissionStatus(): PushPermissionStatus {
        val granted = NotificationManagerCompat.from(context).areNotificationsEnabled()
        return PushPermissionStatus(status = if (granted) "granted" else "denied")
    }
}
```

</details>

### Payment

<details>
<summary>iOS — PaymentProvider (StoreKit 2)</summary>

```swift
import RynBridgePayment
import StoreKit

class MyPaymentProvider: PaymentProvider {
    func getProducts(productIds: [String]) async throws -> [Product] {
        let storeProducts = try await StoreKit.Product.products(for: Set(productIds))
        return storeProducts.map { p in
            Product(id: p.id, title: p.displayName, description: p.description,
                    price: p.displayPrice, currency: p.priceFormatStyle.currencyCode ?? "USD")
        }
    }

    func purchase(productId: String, quantity: Int) async throws -> PurchaseResult {
        guard let product = try await StoreKit.Product.products(for: [productId]).first else {
            throw RynBridgeError(code: .unknown, message: "Product not found")
        }
        let result = try await product.purchase()
        // Handle result, verify receipt...
        return PurchaseResult(transactionId: "...", productId: productId, receipt: "...")
    }

    func restorePurchases() async throws -> [Transaction] {
        // Iterate Transaction.currentEntitlements
        return []
    }

    func finishTransaction(transactionId: String) async throws {
        // Mark transaction as finished
    }
}
```

</details>

<details>
<summary>Android — PaymentProvider (Google Play Billing)</summary>

```kotlin
import io.rynbridge.payment.*

class MyPaymentProvider(private val activity: Activity) : PaymentProvider {
    private val billingClient = BillingClient.newBuilder(activity)
        .setListener { /* handle updates */ }
        .enablePendingPurchases()
        .build()

    override suspend fun getProducts(productIds: List<String>): List<Product> {
        // Query ProductDetails from Google Play
        return productIds.map { id ->
            Product(id = id, title = "...", description = "...", price = "...", currency = "USD")
        }
    }

    override suspend fun purchase(productId: String, quantity: Int): PurchaseResult {
        // Launch billing flow
        return PurchaseResult(transactionId = "...", productId = productId, receipt = "...")
    }

    override suspend fun restorePurchases(): List<Transaction> {
        // Query purchase history
        return emptyList()
    }

    override suspend fun finishTransaction(transactionId: String) {
        // Acknowledge/consume purchase
    }
}
```

</details>

### Media

<details>
<summary>iOS — MediaProvider</summary>

```swift
import RynBridgeMedia
import AVFoundation

class MyMediaProvider: MediaProvider {
    private var players: [String: AVAudioPlayer] = [:]
    private var recorder: AVAudioRecorder?

    func playAudio(source: String, loop: Bool, volume: Double) async throws -> String {
        let url = URL(string: source)!
        let data = try await URLSession.shared.data(from: url).0
        let player = try AVAudioPlayer(data: data)
        player.numberOfLoops = loop ? -1 : 0
        player.volume = Float(volume)
        player.play()
        let playerId = UUID().uuidString
        players[playerId] = player
        return playerId
    }

    func pauseAudio(playerId: String) async throws {
        players[playerId]?.pause()
    }

    func stopAudio(playerId: String) async throws {
        players[playerId]?.stop()
        players.removeValue(forKey: playerId)
    }

    func getAudioStatus(playerId: String) async throws -> AudioStatus {
        guard let player = players[playerId] else {
            throw RynBridgeError(code: .unknown, message: "Player not found")
        }
        return AudioStatus(position: player.currentTime, duration: player.duration, isPlaying: player.isPlaying)
    }

    func startRecording(format: String, quality: String) async throws -> String {
        // Set up AVAudioRecorder...
        return UUID().uuidString
    }

    func stopRecording(recordingId: String) async throws -> RecordingResult {
        recorder?.stop()
        return RecordingResult(filePath: "/path/to/recording", duration: 10.0, size: 1024)
    }

    func pickMedia(type: String, multiple: Bool) async throws -> [MediaFile] {
        // Present PHPickerViewController...
        return []
    }
}
```

</details>

### Crypto

<details>
<summary>iOS — CryptoProvider</summary>

```swift
import RynBridgeCrypto
import CryptoKit

class MyCryptoProvider: CryptoProvider {
    private var privateKey: Curve25519.KeyAgreement.PrivateKey?
    private var symmetricKey: SymmetricKey?
    private var keyCreatedAt: Date?

    func generateKeyPair() async throws -> String {
        let key = Curve25519.KeyAgreement.PrivateKey()
        privateKey = key
        keyCreatedAt = Date()
        return key.publicKey.rawRepresentation.base64EncodedString()
    }

    func performKeyExchange(remotePublicKey: String) async throws -> Bool {
        guard let pk = privateKey,
              let remoteData = Data(base64Encoded: remotePublicKey) else { return false }
        let remotePK = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: remoteData)
        let shared = try pk.sharedSecretFromKeyAgreement(with: remotePK)
        symmetricKey = shared.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(), sharedInfo: Data(), outputByteCount: 32)
        return true
    }

    func encrypt(data: String, associatedData: String?) async throws -> EncryptResult {
        guard let key = symmetricKey else { throw RynBridgeError(code: .unknown, message: "No session") }
        let plaintext = Data(data.utf8)
        let aad = associatedData.map { Data($0.utf8) }
        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: aad ?? Data())
        return EncryptResult(
            ciphertext: sealed.ciphertext.base64EncodedString(),
            iv: sealed.nonce.withUnsafeBytes { Data($0) }.base64EncodedString(),
            tag: sealed.tag.base64EncodedString()
        )
    }

    func decrypt(ciphertext: String, iv: String, tag: String, associatedData: String?) async throws -> String {
        guard let key = symmetricKey else { throw RynBridgeError(code: .unknown, message: "No session") }
        let box = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: Data(base64Encoded: iv)!),
            ciphertext: Data(base64Encoded: ciphertext)!,
            tag: Data(base64Encoded: tag)!
        )
        let aad = associatedData.map { Data($0.utf8) }
        let plaintext = try AES.GCM.open(box, using: key, authenticating: aad ?? Data())
        return String(data: plaintext, encoding: .utf8)!
    }

    func getStatus() async throws -> CryptoStatus {
        CryptoStatus(
            initialized: symmetricKey != nil,
            keyCreatedAt: keyCreatedAt?.ISO8601Format(),
            algorithm: "X25519+AES-256-GCM"
        )
    }

    func rotateKeys() async throws -> String {
        return try await generateKeyPair()
    }
}
```

</details>

---

## 4. Register Modules on Native Side

### iOS

```swift
import RynBridge
import RynBridgeAuth
import RynBridgePush
import RynBridgePayment
import RynBridgeMedia
import RynBridgeCrypto

let transport = WKWebViewTransport(webView: webView)
let bridge = RynBridge(transport: transport)

bridge.register(AuthModule(provider: MyAuthProvider()))
bridge.register(PushModule(provider: MyPushProvider()))
bridge.register(PaymentModule(provider: MyPaymentProvider()))
bridge.register(MediaModule(provider: MyMediaProvider()))
bridge.register(CryptoModule(provider: MyCryptoProvider()))
```

### Android

```kotlin
import io.rynbridge.core.*
import io.rynbridge.auth.AuthModule
import io.rynbridge.push.PushModule
import io.rynbridge.payment.PaymentModule
import io.rynbridge.media.MediaModule
import io.rynbridge.crypto.CryptoModule

val transport = WebViewTransport(webView)
webView.addJavascriptInterface(transport, "RynBridgeAndroid")
val bridge = RynBridge(transport)

bridge.register(AuthModule(MyAuthProvider(this)))
bridge.register(PushModule(MyPushProvider(this)))
bridge.register(PaymentModule(MyPaymentProvider(this)))
bridge.register(MediaModule(MyMediaProvider(this)))
bridge.register(CryptoModule(MyCryptoProvider()))
```

---

## 5. Use Modules from Web

### Auth — Login Flow

```typescript
// Login
const result = await auth.login({ provider: 'google', scopes: ['email', 'profile'] });
console.log(result.token, result.user);

// Check auth state
const token = await auth.getToken();
if (token.token) {
  console.log('Logged in, expires at:', token.expiresAt);
}

// Listen for auth changes
const unsub = auth.onAuthStateChange((state) => {
  console.log('Authenticated:', state.authenticated, 'User:', state.user);
});

// Logout
await auth.logout();
unsub(); // cleanup
```

### Push — Notification Setup

```typescript
// Request permission first
const { granted } = await push.requestPermission();
if (!granted) return;

// Register for push
const reg = await push.register();
console.log('Push token:', reg.token);

// Listen for notifications
const unsub = push.onNotification((notification) => {
  console.log(notification.title, notification.body, notification.data);
});

// Listen for token refresh
push.onTokenRefresh(({ token }) => {
  sendTokenToServer(token);
});
```

### Payment — In-App Purchase

```typescript
// Get product info
const { products } = await payment.getProducts({ productIds: ['premium_monthly'] });
console.log(products[0].title, products[0].price);

// Purchase
const receipt = await payment.purchase({ productId: 'premium_monthly' });
await verifyReceiptOnServer(receipt.receipt);
await payment.finishTransaction({ transactionId: receipt.transactionId });

// Restore purchases
const { transactions } = await payment.restorePurchases();

// Listen for transaction updates
payment.onTransactionUpdate((update) => {
  console.log(update.transactionId, update.status);
});
```

### Media — Audio & Recording

```typescript
// Play audio
const { playerId } = await media.playAudio({
  source: 'https://example.com/song.mp3',
  loop: false,
  volume: 0.8,
});

// Check playback status
const status = await media.getAudioStatus({ playerId });
console.log(`${status.position}s / ${status.duration}s`);

// Record audio
const { recordingId } = await media.startRecording({ format: 'm4a', quality: 'high' });
// ... later
const recording = await media.stopRecording({ recordingId });
console.log(recording.filePath, recording.duration);

// Pick media from gallery
const { files } = await media.pickMedia({ type: 'image', multiple: true });
files.forEach((f) => console.log(f.name, f.mimeType, f.size));

// Listen for playback completion
media.onPlaybackComplete(({ playerId }) => {
  console.log('Finished:', playerId);
});
```

### Crypto — End-to-End Encryption

```typescript
// Generate key pair
const { publicKey } = await crypto.generateKeyPair();
sendPublicKeyToServer(publicKey);

// Perform key exchange with remote party
const remotePublicKey = await getRemotePublicKey();
const { sessionEstablished } = await crypto.performKeyExchange({ remotePublicKey });

if (sessionEstablished) {
  // Encrypt
  const encrypted = await crypto.encrypt({ data: 'Hello, secure world!' });
  // → { ciphertext, iv, tag }

  // Decrypt
  const { plaintext } = await crypto.decrypt(encrypted);
  console.log(plaintext); // 'Hello, secure world!'
}

// Check status
const status = await crypto.getStatus();
console.log(status.initialized, status.algorithm);

// Rotate keys periodically
const newKey = await crypto.rotateKeys();
```

---

## 6. Event Stream Cleanup

Always unsubscribe when your component unmounts:

```typescript
// React example
useEffect(() => {
  const unsub = auth.onAuthStateChange((state) => {
    setUser(state.user);
  });
  return () => unsub();
}, []);
```

---

## 7. Error Handling

All module methods propagate `RynBridgeError`:

```typescript
import { RynBridgeError } from '@rynbridge/core';

try {
  await payment.purchase({ productId: 'premium' });
} catch (error) {
  if (error instanceof RynBridgeError) {
    switch (error.code) {
      case 'TIMEOUT':
        showRetryDialog();
        break;
      case 'MODULE_NOT_FOUND':
        console.error('Payment module not registered on native side');
        break;
      default:
        console.error(error.message);
    }
  }
}
```

---

## Module API Summary

| Module | Methods | Events |
|--------|---------|--------|
| **Auth** | `login`, `logout`, `getToken`, `refreshToken`, `getUser` | `onAuthStateChange` |
| **Push** | `register`, `unregister`, `getToken`, `requestPermission`, `getPermissionStatus` | `onNotification`, `onTokenRefresh` |
| **Payment** | `getProducts`, `purchase`, `restorePurchases`, `finishTransaction` | `onTransactionUpdate` |
| **Media** | `playAudio`, `pauseAudio`, `stopAudio`, `getAudioStatus`, `startRecording`, `stopRecording`, `pickMedia` | `onPlaybackComplete` |
| **Crypto** | `generateKeyPair`, `performKeyExchange`, `encrypt`, `decrypt`, `getStatus`, `rotateKeys` | — |

For detailed API documentation, see:
- [Auth API](../api/auth.md)
- [Push API](../api/push.md)
- [Payment API](../api/payment.md)
- [Media API](../api/media.md)
- [Crypto API](../api/crypto.md)

---

## Phase 3 Modules

Phase 3 modules follow the same pattern. Most ship with **default providers** so you can use them immediately without custom implementations.

### Install

```bash
# Web
npm install @rynbridge/share @rynbridge/contacts @rynbridge/calendar \
  @rynbridge/navigation @rynbridge/bluetooth @rynbridge/health \
  @rynbridge/analytics @rynbridge/speech @rynbridge/background-task
```

### Register with Default Providers

#### iOS

```swift
import RynBridgeShare
import RynBridgeContacts
import RynBridgeBluetooth

bridge.register(ShareModule(provider: DefaultShareProvider()))
bridge.register(ContactsModule(provider: DefaultContactsProvider()))
bridge.register(BluetoothModule(provider: DefaultBluetoothProvider()))
```

#### Android

```kotlin
import io.rynbridge.share.*
import io.rynbridge.contacts.*
import io.rynbridge.bluetooth.*

bridge.register(ShareModule(DefaultShareProvider(context)))
bridge.register(ContactsModule(DefaultContactsProvider(context)))
bridge.register(BluetoothModule(DefaultBluetoothProvider(context)))
```

### Permission Handling

Phase 3 modules that access protected APIs check permissions before each operation. If permissions are missing, a `RynBridgeError` is thrown with a descriptive message.

```typescript
import { RynBridgeError } from '@rynbridge/core';

try {
  const contacts = await contactsModule.getContacts({});
} catch (error) {
  if (error instanceof RynBridgeError) {
    // error.message: "Contacts read permission denied. Required: READ_CONTACTS"
    await requestContactsPermission();
  }
}
```

See the [Providers Guide](../guides/providers.md) for default provider details and required permissions.
