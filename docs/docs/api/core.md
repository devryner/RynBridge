---
sidebar_position: 1
---

# Core API

`@rynbridge/core` provides the bridge infrastructure.

## RynBridge

Main facade class.

```typescript
import { RynBridge, WebViewTransport } from '@rynbridge/core';

const bridge = new RynBridge({ timeout: 30000, version: '1.0.0' }, transport);
```

### Constructor

```typescript
new RynBridge(config: BridgeConfig, transport: Transport)
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `timeout` | `number` | `30000` | Request timeout in ms |
| `version` | `string` | `'0.1.0'` | SDK version for negotiation |

### Methods

#### `call(module, action, payload?): Promise<Record<string, unknown>>`

Send a request and wait for a response.

#### `send(module, action, payload?): void`

Send a fire-and-forget message.

#### `onEvent(key, handler): void`

Subscribe to events. Key format: `module:action`.

#### `offEvent(key, handler): void`

Unsubscribe from events.

#### `register(module: BridgeModule): void`

Register a module for handling incoming requests from native.

#### `dispose(): void`

Clean up resources and pending callbacks.

## Transport Interface

```typescript
interface Transport {
  send(message: string): void;
  onMessage(handler: (message: string) => void): void;
  dispose(): void;
}
```

### WebViewTransport

Production transport for WebView environments.

### MockTransport

Testing transport with message recording and response simulation.

```typescript
import { MockTransport } from '@rynbridge/core';

const transport = new MockTransport();
const bridge = new RynBridge({}, transport);

// Inspect sent messages
console.log(transport.sent);

// Simulate native response
transport.simulateIncoming(JSON.stringify(response));
```

## Types

```typescript
interface BridgeConfig {
  timeout?: number;
  version?: string;
}

interface BridgeRequest {
  id: string;
  module: string;
  action: string;
  payload: Record<string, unknown>;
  version: string;
}

interface BridgeResponse {
  id: string;
  status: 'success' | 'error';
  payload: Record<string, unknown>;
  error: BridgeErrorData | null;
}

interface BridgeModule {
  name: string;
  version: string;
  actions: Record<string, ActionHandler>;
}
```
