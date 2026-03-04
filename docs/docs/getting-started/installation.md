---
sidebar_position: 1
---

# Installation

RynBridge is distributed as modular packages. Install only what you need.

## Web SDK

```bash
# Core (required)
npm install @rynbridge/core

# Modules (pick what you need)
npm install @rynbridge/device
npm install @rynbridge/storage
npm install @rynbridge/secure-storage
npm install @rynbridge/ui
```

Or use the CLI to scaffold a project:

```bash
npx @rynbridge/cli init
```

## iOS SDK

Add the packages to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/user/rynbridge-ios.git", from: "0.1.0")
]
```

Then add the targets you need:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "RynBridgeCore", package: "rynbridge-ios"),
    .product(name: "RynBridgeDevice", package: "rynbridge-ios"),
])
```

## Android SDK

Add to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("io.rynbridge:core:0.1.0")
    implementation("io.rynbridge:device:0.1.0")
    implementation("io.rynbridge:storage:0.1.0")
    implementation("io.rynbridge:ui:0.1.0")
}
```

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| Web      | ES2022+        |
| iOS      | 17+            |
| Android  | API 30+        |
| Node.js  | 20+            |
