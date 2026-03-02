# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RynBridge is a lightweight, modular bridge framework for Web ↔ Native (iOS/Android) communication in WebView-based hybrid apps. It standardizes the communication interface and allows selective module installation. The project plan is written in Korean — see `PROJECT_PLAN.md` for the full spec.

**Status:** Early stage — project plan exists, implementation not yet started.

## Architecture

Three-platform bridge with a shared JSON message protocol:

- **Web SDK** (TypeScript) → Message Serializer → JSON over WebView Bridge → Message Deserializer → **Native SDK** (Swift / Kotlin)
- Communication patterns: Request-Response (Promise-based), Event Streams, Batch Calls, Fire-and-Forget
- Messages use UUID v4 correlation IDs with module/action routing and version negotiation
- Modules are independent plugins that depend only on `core`

### Message Protocol Format
```json
{ "id": "uuid-v4", "module": "device", "action": "getCamera", "payload": {}, "version": "1.0.0" }
```

## Repository Structure (Planned)

```
packages/           # npm packages (Web TypeScript SDK)
ios/                # Swift packages via SPM
android/            # Kotlin Gradle modules
contracts/          # Shared JSON schema definitions (codegen source of truth)
playground/         # Demo apps (web, iOS, Android)
docs/               # Docusaurus documentation site
```

## Technology Stack & Build Commands

| Platform | Language | Build Tool | Test Framework | Linter |
|----------|----------|------------|----------------|--------|
| Web | TypeScript | Rollup, Turborepo | Vitest | ESLint |
| iOS | Swift 5.9+ | SPM | XCTest | SwiftLint |
| Android | Kotlin | Gradle KTS | JUnit | ktlint |

### Web (Turborepo monorepo)
```bash
# These commands are planned — adjust once package.json exists
turbo build              # Build all web packages
turbo test               # Run all web tests
turbo lint               # Lint all web packages
npx vitest run           # Run web tests (single package)
npx vitest run <file>    # Run a single test file
```

### iOS
```bash
swift build
swift test
swiftlint
```

### Android
```bash
./gradlew build
./gradlew test
./gradlew ktlintCheck
```

## Module System

All modules follow the pattern: `@rynbridge/<module>` (npm) / `RynBridge<Module>` (SPM) / `io.rynbridge:<module>` (Gradle).

Phase 1 (core): core, device, storage, secure-storage, ui
Phase 2 (extended): auth, push, payment, media, crypto
Phase 3 (advanced): analytics, navigation, share, health, bluetooth, contacts, calendar, speech, background-task

## Code Generation Pipeline

JSON Schema definitions in `contracts/` are the source of truth. Codegen produces:
- TypeScript types (web)
- Swift Codable structs (iOS)
- Kotlin data classes (Android)

Changes to the bridge API should start with updating the contract schema, then regenerating platform code.

## Key Conventions

- **Type safety across all three platforms** — every bridge call must be type-safe end-to-end
- **Consistent API surface** — same interface shape regardless of platform
- **Minimal core** — core handles only message serialization, callback management, Promise communication, event pub/sub, version negotiation, error handling, and timeouts
- **Module independence** — each module depends only on core, never on other modules
- **Semantic Versioning** on all packages with version negotiation for graceful degradation

## Performance Targets

- Core bundle: < 5KB gzipped
- Individual modules: < 3KB gzipped
- Message round-trip latency: < 10ms

## Platform Minimums

- iOS 17+
- Android API 30+ (Android 11)
- ES2022+

## Distribution

- npm: `@rynbridge/*`
- Swift Package Manager: GitHub releases
- Maven Central: `io.rynbridge:*`
