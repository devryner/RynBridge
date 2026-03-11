---
sidebar_position: 3
---

# Android Platform Guide

Setting up RynBridge native handlers in your Android app.

## Requirements

- Android API 30+
- Kotlin 1.9+
- WebView

## Setup

### 1. Add Dependencies

```kotlin
// build.gradle.kts
dependencies {
    implementation("io.rynbridge:core:0.1.0")
    implementation("io.rynbridge:device:0.1.0")
    implementation("io.rynbridge:storage:0.1.0")
    implementation("io.rynbridge:ui:0.1.0")
}
```

### 2. Initialize Bridge

```kotlin
import io.rynbridge.core.RynBridge
import io.rynbridge.device.DeviceModule

class MainActivity : AppCompatActivity() {
    private lateinit var bridge: RynBridge

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val webView = findViewById<WebView>(R.id.webView)
        bridge = RynBridge(webView)

        val device = DeviceModule(MyDeviceProvider(this))
        bridge.register(device)
    }
}
```

### 3. Use Default Providers

Each module ships with a **default provider** that works out of the box:

```kotlin
import io.rynbridge.device.DeviceModule
import io.rynbridge.device.DefaultDeviceInfoProvider
import io.rynbridge.media.MediaModule
import io.rynbridge.media.DefaultMediaProvider
import io.rynbridge.bluetooth.BluetoothModule
import io.rynbridge.bluetooth.DefaultBluetoothProvider

val device = DeviceModule(DefaultDeviceInfoProvider(context))
val media = MediaModule(DefaultMediaProvider(context))
val bluetooth = BluetoothModule(DefaultBluetoothProvider(context))

bridge.register(device)
bridge.register(media)
bridge.register(bluetooth)
```

Or implement your own provider for custom behavior:

```kotlin
class MyDeviceProvider(private val context: Context) : DeviceInfoProvider {
    override suspend fun getInfo(): DeviceInfo {
        return DeviceInfo(
            platform = "android",
            osVersion = Build.VERSION.RELEASE,
            model = Build.MODEL,
            appVersion = context.packageManager
                .getPackageInfo(context.packageName, 0).versionName ?: "unknown"
        )
    }
}
```

See the [Providers Guide](../guides/providers.md) for a full list of default providers.

## Permission Handling

Default providers check `context.checkSelfPermission()` before accessing protected APIs. If permission is not granted, a `RynBridgeError` is thrown with a descriptive message.

| Module | Required Permissions |
|--------|---------------------|
| Device | `VIBRATE` |
| Contacts | `READ_CONTACTS`, `WRITE_CONTACTS` |
| Calendar | `READ_CALENDAR`, `WRITE_CALENDAR` |
| Bluetooth | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (API 31+) |
| Health | Health Connect permissions |
| Media | `RECORD_AUDIO` (recording only) |

```kotlin
// Errors propagate to the web layer automatically
// Web side receives: { code: "UNKNOWN", message: "Bluetooth permissions denied. Required: BLUETOOTH_SCAN, BLUETOOTH_CONNECT" }
```

:::tip
Default providers only **check** permissions — they don't request them at runtime. Your app must request permissions through the standard Android permission flow (e.g., `ActivityCompat.requestPermissions()`) before calling bridge methods.
:::

## Code Generation

Use the CLI to generate Kotlin data classes from contracts:

```bash
npx rynbridge generate --target kotlin --outdir android/generated
```

This generates data classes with `toPayload()` and `fromPayload()` methods.
