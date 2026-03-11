---
sidebar_position: 16
---

# WebView Module API

`@rynbridge/webview` — WebView control and in-app browser.

## Setup

```typescript
import { WebViewModule } from '@rynbridge/webview';

const webview = new WebViewModule(bridge);
```

## Methods

### `open(payload): Promise<void>`

Opens an in-app browser or WebView overlay.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | `string` | Yes | URL to load |
| `title` | `string` | No | Title displayed in the toolbar |
| `showToolbar` | `boolean` | No | Whether to show the navigation toolbar |

```typescript
await webview.open({ url: 'https://rynbridge.dev/docs', title: 'Documentation', showToolbar: true });
```

### `close(): Promise<void>`

Closes the currently open in-app browser.

```typescript
await webview.close();
```

### `executeJavaScript(payload): Promise<ExecuteResult>`

Executes a JavaScript snippet in the in-app browser context.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `script` | `string` | Yes | JavaScript code to execute |

```typescript
const { result } = await webview.executeJavaScript({ script: 'document.title' });
// { result: 'RynBridge Docs' }
```

### `goBack(): Promise<void>`

Navigates the in-app browser back one page.

```typescript
await webview.goBack();
```

### `goForward(): Promise<void>`

Navigates the in-app browser forward one page.

```typescript
await webview.goForward();
```

### `reload(): Promise<void>`

Reloads the current page in the in-app browser.

```typescript
await webview.reload();
```

### `onNavigationStateChange(listener): () => void`

Subscribes to navigation state changes in the in-app browser. Returns an unsubscribe function.

```typescript
const unsubscribe = webview.onNavigationStateChange((state) => {
  console.log('URL:', state.url);
  console.log('Title:', state.title);
  console.log('Can go back:', state.canGoBack);
  console.log('Loading:', state.loading);
});

// Later: stop listening
unsubscribe();
```

## Types

```typescript
interface OpenPayload {
  url: string;
  title?: string;
  showToolbar?: boolean;
}

interface ExecuteJavaScriptPayload {
  script: string;
}

interface ExecuteResult {
  result: string | null;
}

interface NavigationState {
  url: string;
  title: string;
  canGoBack: boolean;
  canGoForward: boolean;
  loading: boolean;
}
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `WebViewProvider` | `open`, `close`, `executeJavaScript`, `goBack`, `goForward`, `reload` |
| Android | `WebViewProvider` | Same as iOS |
