# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RynBridge is a lightweight, modular bridge framework for Web ↔ Native (iOS/Android) communication in WebView-based hybrid apps. It standardizes the communication interface and allows selective module installation. The project plan is written in Korean — see `PROJECT_PLAN.md` for the full spec.

**Status:** All 3 platforms (Web/iOS/Android) fully implemented with default providers for every module.

## Build & Test Commands

Package manager is **pnpm** (v9.15.4, Node 20 via `.nvmrc`). Monorepo managed by Turborepo.

```bash
pnpm install                          # Install all dependencies
pnpm build                            # Build all packages (turbo)
pnpm test                             # Run all tests (turbo)
pnpm lint                             # Lint all packages (turbo)

# Single package (run from packages/<name>/)
pnpm --filter @rynbridge/core test    # Test a specific package
pnpm --filter @rynbridge/core build   # Build a specific package
npx vitest run src/__tests__/X.test.ts  # Run a single test file (from package dir)

# iOS build
cd ios && swift build                 # Build all iOS targets
cd ios && swift build --target RynBridgeDevice  # Build single target

# Android build
cd android && ./gradlew compileDebugKotlin      # Build all Android modules
cd android && ./gradlew :device:compileDebugKotlin  # Build single module
```

Each package uses: `rollup -c rollup.config.mjs` for build, `vitest run` for test, `tsc --noEmit` for lint.

## Architecture

Three-platform bridge with a shared JSON message protocol:

- **Web SDK** (TypeScript) → Message Serializer → JSON over WebView Bridge → Message Deserializer → **Native SDK** (Swift / Kotlin)
- Communication patterns: Request-Response (Promise-based), Event Streams, Fire-and-Forget
- Messages use UUID v4 correlation IDs with module/action routing and version negotiation

### Message Protocol

```json
{ "id": "uuid-v4", "module": "device", "action": "getInfo", "payload": {}, "version": "1.0.0" }
```

JSON Schema definitions in `contracts/` are the source of truth for all platforms. Each module has `<action>.request.schema.json` and `<action>.response.schema.json` files.

### Core Internal Components (`packages/core/src/`)

- **RynBridge** — Main facade. Orchestrates all components below. Accepts a `Transport` and `BridgeConfig`.
- **Transport** — Interface with `send()`, `onMessage()`, `dispose()`. Two implementations:
  - `WebViewTransport` — Production transport. Sends via `window.webkit.messageHandlers.RynBridge` (iOS) or `window.RynBridgeAndroid` (Android). Receives via `window.__rynbridge_receive`.
  - `MockTransport` — For testing. Records sent messages in `.sent[]` and provides `simulateIncoming()`.
- **MessageSerializer / MessageDeserializer** — JSON encode/decode with UUID generation and type discrimination (request vs response).
- **CallbackRegistry** — Maps request IDs to pending Promises with timeout support.
- **EventEmitter** — Pub/sub for native-to-web event streams (`module:action` pattern).
- **ModuleRegistry** — Registers `BridgeModule` objects and routes incoming requests to action handlers.
- **VersionNegotiator** — Semantic version comparison for compatibility checks.

### Module Pattern

Every module package (device, storage, secure-storage, ui) follows the same structure:
- Wraps a `RynBridge` instance, received via constructor injection
- Defines a `MODULE` constant (e.g., `'device'`)
- Methods delegate to `bridge.call(MODULE, action, payload)` (request-response) or `bridge.send(MODULE, action, payload)` (fire-and-forget)
- Types are defined in `types.ts`, re-exported from `index.ts`
- Modules depend on `@rynbridge/core` as a `peerDependency` (linked via `workspace:*` in dev)

### Native Provider Pattern

On iOS and Android, each module delegates to a **Provider** interface/protocol. Default providers are named `Default<Module>Provider` (e.g., `DefaultDeviceInfoProvider`, `DefaultStorageProvider`). Third-party specific providers use their service name (e.g., `FirebaseFCMPushProvider`, `GoogleAuthProvider`, `KakaoAuthProvider`).

**iOS providers** are embedded in the module's Swift file or in a separate `Default<Module>Provider.swift`.
**Android providers** are in `Default<Module>Provider.kt` within each module's source directory.

Some provider methods that require Activity context (e.g., `capturePhoto`, `getLocation`, `authenticate` on Device) throw `UnsupportedOperationException` in the default provider — consumers should provide a custom Activity-aware provider for these features.

### Key Types (`packages/core/src/types.ts`)

- `BridgeRequest` / `BridgeResponse` — Wire format types
- `BridgeModule` — Module registration: `{ name, version, actions: Record<string, ActionHandler> }`
- `Transport` — Transport interface
- `BridgeConfig` — `{ timeout?: number, version?: string }`

### Android Key Types (`android/core/`)

- `BridgeValue` — Sealed class with `StringValue`, `IntValue` (Long), `DoubleValue`, `BoolValue`, `ArrayValue`, `DictValue`, `NullValue`. Access via `.stringValue`, `.intValue`, `.doubleValue`, `.boolValue`, `.arrayValue`, `.dictionaryValue`. Create via `BridgeValue.string()`, `.int()`, `.double()`, `.bool()`, `.array()`, `.dict()`, `.nullValue()`.
- `BridgeModule` — Interface: `name: String`, `version: String`, `actions: Map<String, ActionHandler>`
- `ActionHandler` — `suspend (Map<String, BridgeValue>) -> Map<String, BridgeValue>`
- `RynBridgeError` — `(code: ErrorCode, message: String)`

## Module System

All modules follow the naming pattern: `@rynbridge/<module>` (npm) / `RynBridge<Module>` (SPM) / `io.rynbridge:<module>` (Gradle).

### All Modules (implemented on all 3 platforms)

**Phase 1:** core, device, storage, secure-storage, ui
**Phase 2:** auth, push, payment, media, crypto
**Phase 3:** share, contacts, calendar, navigation, webview, speech, analytics, translation, bluetooth, health, background-task
**Platform-specific:** push-fcm (Firebase), share-kakao (Kakao), auth-google, auth-kakao, auth-apple (iOS), push-apns (iOS), payment-storekit (iOS), payment-google-play (Android)

## Key Conventions

- **Type safety across all three platforms** — every bridge call must be type-safe end-to-end
- **Consistent API surface** — same interface shape regardless of platform
- **Minimal core** — core handles only message serialization, callback management, Promise communication, event pub/sub, version negotiation, error handling, and timeouts
- **Module independence** — each module depends only on core, never on other modules
- **Contract-first** — Changes to the bridge API should start with updating the contract schema in `contracts/`, then updating platform code
- **Error codes** — Use `ErrorCode` constants from `errors.ts` (TIMEOUT, MODULE_NOT_FOUND, ACTION_NOT_FOUND, INVALID_MESSAGE, SERIALIZATION_ERROR, TRANSPORT_ERROR, VERSION_MISMATCH, UNKNOWN)
- **Default provider naming** — All default providers use `Default` prefix (e.g., `DefaultStorageProvider`, `DefaultSecureStorageProvider`)

## Performance Targets

- Core bundle: < 5KB gzipped
- Individual modules: < 3KB gzipped
- Message round-trip latency: < 10ms

## Platform Minimums

- iOS 17+ / Android API 30+ / ES2022+

## Android External Dependencies

Some Android modules require additional libraries beyond core:

| Module | Dependency | Version Catalog Key |
|--------|-----------|-------------------|
| secure-storage | `androidx.security:security-crypto` | `libs.security.crypto` |
| ui | `androidx.appcompat:appcompat` | `libs.appcompat` |
| health | `androidx.health.connect:connect-client` | `libs.health.connect` |
| background-task | `androidx.work:work-runtime-ktx` | `libs.work.runtime` |
| translation | `com.google.mlkit:translate` + `language-id` | `libs.mlkit.translate`, `libs.mlkit.language.id` |
| share-kakao | `com.kakao.sdk:v2-share` + `v2-template` | `libs.kakao.share`, `libs.kakao.template` |
| push-fcm | `com.google.firebase:firebase-messaging-ktx` | `libs.firebase.messaging` |

Version catalog: `android/gradle/libs.versions.toml`
