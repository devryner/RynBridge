---
sidebar_position: 2
---

# Providers Guide

RynBridge uses the **Provider Pattern** to decouple module interfaces from platform-specific implementations. Each module delegates actual native operations to a provider.

## How It Works

```
Web SDK → Bridge Message → Native Module → Provider → Platform API
```

1. The Web SDK calls `bridge.call('device', 'getInfo', {})`
2. The native `DeviceModule` receives the message
3. The module delegates to its `DeviceInfoProvider`
4. The provider calls platform APIs (UIKit, Android SDK, etc.) and returns the result

## Default Providers

Every module ships with a **default provider** that works out of the box. Default providers use standard platform APIs and cover the most common use cases.

### iOS Default Providers

| Module | Provider | Implementation |
|--------|----------|---------------|
| Device | `DefaultDeviceInfoProvider` | UIDevice, UIScreen |
| Storage | `DefaultStorageProvider` | UserDefaults + FileManager |
| Secure Storage | `DefaultSecureStorageProvider` | Keychain Services |
| UI | `DefaultUIProvider` | UIAlertController, UIKit |
| Auth | `DefaultAuthProvider` | — |
| Push | `DefaultPushProvider` | UNUserNotificationCenter |
| Payment | `DefaultPaymentProvider` | StoreKit 2 |
| Media | `DefaultMediaProvider` | AVFoundation |
| Crypto | `DefaultCryptoProvider` | CryptoKit |
| Analytics | `DefaultAnalyticsProvider` | In-memory |
| Bluetooth | `DefaultBluetoothProvider` | CoreBluetooth |
| Health | `DefaultHealthProvider` | HealthKit |
| Background Task | `DefaultBackgroundTaskProvider` | BGTaskScheduler |
| Translation | `DefaultTranslationProvider` | Apple Translation |

### Android Default Providers

| Module | Provider | Implementation |
|--------|----------|---------------|
| Device | `DefaultDeviceInfoProvider` | Build, BatteryManager |
| Storage | `DefaultStorageProvider` | SharedPreferences + File I/O |
| Secure Storage | `DefaultSecureStorageProvider` | EncryptedSharedPreferences |
| UI | `DefaultUIProvider` | AlertDialog, Toast |
| Auth | `DefaultAuthProvider` | — |
| Push | `DefaultPushProvider` | — |
| Payment | `DefaultPaymentProvider` | — |
| Media | `DefaultMediaProvider` | MediaPlayer |
| Crypto | `DefaultCryptoProvider` | javax.crypto |
| Analytics | `DefaultAnalyticsProvider` | In-memory |
| Bluetooth | `DefaultBluetoothProvider` | BLE Scanner/GATT |
| Health | `DefaultHealthProvider` | Health Connect |
| Background Task | `DefaultBackgroundTaskProvider` | WorkManager |
| Translation | `DefaultTranslationProvider` | ML Kit Translate |

### Platform-Specific Providers

Some modules have specialized providers for third-party services:

| Module | Provider | Service |
|--------|----------|---------|
| Push FCM | `DefaultPushFCMProvider` (iOS) / `FirebasePushFCMProvider` (Android) | Firebase Cloud Messaging |
| Share Kakao | `DefaultKakaoShareProvider` | Kakao SDK |

## Using Default Providers

### iOS

```swift
import RynBridgeDevice

let device = DeviceModule(provider: DefaultDeviceInfoProvider())
bridge.register(module: device)
```

### Android

```kotlin
import io.rynbridge.device.DeviceModule
import io.rynbridge.device.DefaultDeviceInfoProvider

val device = DeviceModule(DefaultDeviceInfoProvider(context))
bridge.register(device)
```

## Creating Custom Providers

When default providers don't meet your needs, implement the provider protocol/interface:

### iOS

```swift
class MyDeviceProvider: DeviceInfoProvider {
    func getInfo() async throws -> [String: BridgeValue] {
        // Your custom implementation
    }

    func getBattery() async throws -> [String: BridgeValue] {
        // Your custom implementation
    }
}

let device = DeviceModule(provider: MyDeviceProvider())
```

### Android

```kotlin
class MyDeviceProvider(private val context: Context) : DeviceInfoProvider {
    override suspend fun getInfo(): Map<String, BridgeValue> {
        // Your custom implementation
    }

    override suspend fun getBattery(): Map<String, BridgeValue> {
        // Your custom implementation
    }
}

val device = DeviceModule(MyDeviceProvider(context))
```

## Best Practices

- **Start with default providers** — they cover most use cases out of the box
- **Create custom providers** only when you need to integrate third-party SDKs or customize behavior
- **Keep providers focused** — one provider per module, implementing only the required interface
- **Use dependency injection** — pass providers to modules via constructors for easy testing
- **Test with mock providers** — create test doubles of your providers for unit testing
