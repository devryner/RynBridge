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

### 3. Implement Providers

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

    override suspend fun getBattery(): BatteryInfo {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return BatteryInfo(
            level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY),
            isCharging = bm.isCharging
        )
    }
}
```

## Code Generation

Use the CLI to generate Kotlin data classes from contracts:

```bash
npx rynbridge generate --target kotlin --outdir android/generated
```

This generates data classes with `toPayload()` and `fromPayload()` methods.
