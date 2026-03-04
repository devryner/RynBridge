---
sidebar_position: 1
---

# Architecture

RynBridge is a three-platform bridge with a shared JSON message protocol.

## Overview

```
Web SDK (TypeScript)
  → Message Serializer
    → JSON over WebView Bridge
      → Message Deserializer
        → Native SDK (Swift / Kotlin)
```

## Core Components

### RynBridge (Facade)

The main entry point that orchestrates all internal components. Accepts a `Transport` and optional `BridgeConfig`.

### Transport

Interface with `send()`, `onMessage()`, and `dispose()`. Two built-in implementations:

- **WebViewTransport** — Production transport for WebView environments
  - iOS: `window.webkit.messageHandlers.RynBridge`
  - Android: `window.RynBridgeAndroid`
  - Receives via `window.__rynbridge_receive`
- **MockTransport** — For testing, records messages and simulates responses

### CallbackRegistry

Maps request IDs to pending Promises with configurable timeout support. Each `bridge.call()` creates a pending entry that resolves when a matching response arrives.

### EventEmitter

Pub/sub system for native-to-web event streams using `module:action` pattern keys.

### ModuleRegistry

Registers `BridgeModule` objects and routes incoming requests to the correct action handler.

### MessageSerializer / MessageDeserializer

JSON encode/decode with UUID v4 generation and type discrimination between requests and responses.

### VersionNegotiator

Semantic version comparison for backward compatibility checks between web and native SDKs.

## Design Principles

- **Minimal core** — Core handles only message plumbing, not business logic
- **Module independence** — Modules depend only on core, never on each other
- **Type safety** — Every bridge call is type-safe across all three platforms
- **Contract-first** — JSON Schema contracts are the source of truth
