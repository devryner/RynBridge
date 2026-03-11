---
sidebar_position: 2
---

# iOS Platform Guide

Setting up RynBridge native handlers in your iOS app.

## Requirements

- iOS 17+
- Swift 5.9+
- WKWebView

## Setup

### 1. Add Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/user/rynbridge-ios.git", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "RynBridgeCore", package: "rynbridge-ios"),
        .product(name: "RynBridgeDevice", package: "rynbridge-ios"),
        .product(name: "RynBridgeStorage", package: "rynbridge-ios"),
        .product(name: "RynBridgeUI", package: "rynbridge-ios"),
    ])
]
```

### 2. Initialize Bridge

```swift
import RynBridgeCore
import RynBridgeDevice

class ViewController: UIViewController {
    let webView = WKWebView()
    var bridge: RynBridge!

    override func viewDidLoad() {
        super.viewDidLoad()

        bridge = RynBridge(webView: webView)

        let device = DeviceModule(provider: MyDeviceProvider())
        bridge.register(module: device)
    }
}
```

### 3. Use Default Providers

Each module ships with a **default provider** that works out of the box:

```swift
import RynBridgeDevice
import RynBridgeMedia
import RynBridgeBluetooth

let device = DeviceModule(provider: DefaultDeviceInfoProvider())
let media = MediaModule(provider: DefaultMediaProvider())
let bluetooth = BluetoothModule(provider: DefaultBluetoothProvider())

bridge.register(module: device)
bridge.register(module: media)
bridge.register(module: bluetooth)
```

Or implement your own provider for custom behavior:

```swift
class MyDeviceProvider: DeviceInfoProvider {
    func getInfo() async -> DeviceInfo {
        DeviceInfo(
            platform: "ios",
            osVersion: UIDevice.current.systemVersion,
            model: UIDevice.current.model,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
    }
}
```

See the [Providers Guide](../guides/providers.md) for a full list of default providers.

## Permission Handling

Default providers automatically check permissions before accessing protected APIs. If permission is denied, a `RynBridgeError` is thrown. For undetermined permissions, providers auto-request access.

| Module | Permission | Behavior |
|--------|-----------|----------|
| Device | Camera (`AVCaptureDevice`) | Auto-request on `capturePhoto` |
| Media | Microphone (`AVAudioSession`) | Auto-request on `startRecording` |
| Health | HealthKit (`HKHealthStore`) | Check via `authorizationStatus` |

```swift
// Errors propagate to the web layer automatically
// Web side receives: { code: "UNKNOWN", message: "Camera permission denied" }
```

## Code Generation

Use the CLI to generate Swift types from contracts:

```bash
npx rynbridge generate --target swift --outdir ios/Generated
```

This generates `Sendable` structs with `toPayload()` and `init(from:)` methods.
