---
sidebar_position: 12
---

# Share Module API

`@rynbridge/share` — Native share sheet for sharing text, URLs, and files.

## Setup

```typescript
import { ShareModule } from '@rynbridge/share';

const share = new ShareModule(bridge);
```

## Methods

### `shareText(payload): Promise<ShareResult>`

Shares plain text via the native share sheet.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | `string` | Yes | Text content to share |
| `title` | `string` | No | Title displayed in the share sheet |

```typescript
const result = await share.shareText({ text: 'Check out RynBridge!', title: 'Share' });
// { shared: true, activityType: 'com.apple.UIKit.activity.CopyToPasteboard' }
```

### `shareUrl(payload): Promise<ShareResult>`

Shares a URL via the native share sheet.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | `string` | Yes | URL to share |
| `title` | `string` | No | Title displayed in the share sheet |

```typescript
const result = await share.shareUrl({ url: 'https://rynbridge.dev', title: 'RynBridge' });
// { shared: true, activityType: 'com.apple.UIKit.activity.Message' }
```

### `shareFile(payload): Promise<ShareResult>`

Shares a file from the local filesystem via the native share sheet.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `filePath` | `string` | Yes | Absolute path to the file |
| `mimeType` | `string` | No | MIME type of the file (e.g., `'application/pdf'`) |

```typescript
const result = await share.shareFile({ filePath: '/path/to/document.pdf', mimeType: 'application/pdf' });
// { shared: true }
```

### `shareImage(payload): Promise<ShareResult>`

Shares a base64-encoded image via the native share sheet.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `imageBase64` | `string` | Yes | Base64-encoded image data |
| `fileName` | `string` | No | File name for the shared image |

```typescript
const result = await share.shareImage({ imageBase64: 'iVBORw0KGgo...', fileName: 'screenshot.png' });
// { shared: true, activityType: 'com.apple.UIKit.activity.SaveToCameraRoll' }
```

## Types

```typescript
interface ShareTextPayload {
  text: string;
  title?: string;
}

interface ShareUrlPayload {
  url: string;
  title?: string;
}

interface ShareFilePayload {
  filePath: string;
  mimeType?: string;
}

interface ShareImagePayload {
  imageBase64: string;
  fileName?: string;
}

interface ShareResult {
  shared: boolean;
  activityType?: string;
}
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `ShareProvider` | `shareText`, `shareUrl`, `shareFile`, `shareImage` |
| Android | `ShareProvider` | Same as iOS |
