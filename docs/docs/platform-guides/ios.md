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

### 3. Implement Providers

Each module requires a platform-specific provider:

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

    func getBattery() async -> BatteryInfo {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return BatteryInfo(
            level: Int(UIDevice.current.batteryLevel * 100),
            isCharging: UIDevice.current.batteryState == .charging
        )
    }
}
```

## Code Generation

Use the CLI to generate Swift types from contracts:

```bash
npx rynbridge generate --target swift --outdir ios/Generated
```

This generates `Sendable` structs with `toPayload()` and `init(from:)` methods.
