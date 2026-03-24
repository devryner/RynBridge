# Development Guide

## Prerequisites

- Node.js 20+ (see `.nvmrc`)
- pnpm 9.15+
- Xcode 15+ (for iOS)
- Android Studio + API 30+ SDK (for Android)

## Commands

```bash
pnpm install                          # Install all dependencies
pnpm build                            # Build all packages
pnpm test                             # Run all tests
pnpm lint                             # Lint all packages

# Single package
pnpm --filter @rynbridge/core test
pnpm --filter @rynbridge/core build
npx vitest run src/__tests__/X.test.ts  # Run a single test file (from package dir)

# iOS
cd ios && swift build
cd ios && swift build --target RynBridgeDevice

# Android
cd android && ./gradlew compileDebugKotlin
cd android && ./gradlew :device:compileDebugKotlin
```

## Build Pipeline

Managed by [Turborepo](https://turbo.build). Build order respects dependencies:

```
core → device, storage, secure-storage, ui, auth, push, payment, media, crypto,
       share, contacts, calendar, navigation, webview, speech, analytics, translation,
       bluetooth, health, background-task, push-fcm, share-kakao → playground-web
```

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

See [`playground/ios/README.md`](../playground/ios/README.md) for detailed setup.

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
