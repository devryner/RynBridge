---
sidebar_position: 1
---

# DevTools

`@rynbridge/devtools` — Debug panel for inspecting bridge messages in real-time.

## Installation

```bash
npm install @rynbridge/devtools
```

## Setup

Wrap your transport with `DevToolsTransport` and attach the panel:

```typescript
import { RynBridge, WebViewTransport } from '@rynbridge/core';
import { DevToolsTransport, DevToolsPanel } from '@rynbridge/devtools';

const innerTransport = new WebViewTransport();
const devtools = new DevToolsTransport(innerTransport);
const bridge = new RynBridge({}, devtools);

// Attach visual panel
DevToolsPanel.attach(devtools.store);
```

## Features

### Message Timeline

The panel shows all bridge messages in chronological order with:

- **Direction arrows** — `↑` outgoing (red), `↓` incoming (green)
- **Module.Action** — e.g., `device.getInfo`
- **Status badge** — pending (yellow), success (green), error (red), timeout (orange)
- **Latency** — Round-trip time for request-response pairs

### Payload Inspector

Click any message to expand its JSON payload. Shows request payload, response payload, and error details.

### Filters

Filter messages by:
- **Module** — Show only specific module messages
- **Direction** — Outgoing or incoming only
- **Status** — Filter by status (pending, success, error, timeout)

### Statistics

Header shows real-time stats:
- Total message count
- Average latency

## Architecture

### DevToolsTransport

A Transport decorator that intercepts all messages passing through:

```typescript
class DevToolsTransport implements Transport {
  readonly store: MessageStore;
  // Intercepts send() and onMessage() to record messages
}
```

### MessageStore

In-memory message store with:
- Automatic request-response matching via correlation ID
- Latency calculation
- Filtering and statistics
- Event subscription for UI updates

```typescript
const store = devtools.store;

// Get all messages
store.getAll();

// Filter messages
store.getFiltered({ module: 'device', status: 'success' });

// Get statistics
store.getStats(); // { count: 42, avgLatency: 12.5 }

// Subscribe to changes
const unsubscribe = store.subscribe((event) => {
  console.log(event.type, event);
});
```

## Production Usage

Only include DevTools in development:

```typescript
import { RynBridge, WebViewTransport } from '@rynbridge/core';

let transport: Transport = new WebViewTransport();

if (process.env.NODE_ENV === 'development') {
  const { DevToolsTransport, DevToolsPanel } = await import('@rynbridge/devtools');
  transport = new DevToolsTransport(transport);
  DevToolsPanel.attach((transport as DevToolsTransport).store);
}

const bridge = new RynBridge({}, transport);
```
