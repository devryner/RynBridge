---
sidebar_position: 5
---

# UI Module API

`@rynbridge/ui` — Native UI components: alerts, toasts, action sheets, keyboard control.

## Setup

```typescript
import { UIModule } from '@rynbridge/ui';

const ui = new UIModule(bridge);
```

## Methods

### `showAlert(payload): Promise<void>`

Show a native alert dialog.

```typescript
await ui.showAlert({
  title: 'Warning',
  message: 'Are you sure?',
  buttonText: 'OK',
});
```

### `showConfirm(payload): Promise<boolean>`

Show a confirmation dialog. Returns `true` if confirmed.

```typescript
const confirmed = await ui.showConfirm({
  title: 'Delete',
  message: 'Delete this item?',
  confirmText: 'Delete',
  cancelText: 'Cancel',
});
```

### `showToast(payload): void`

Show a brief toast message. Fire-and-forget.

```typescript
ui.showToast({ message: 'Saved!', duration: 'short' });
```

### `showActionSheet(payload): Promise<number>`

Show an action sheet with multiple options. Returns the selected index.

```typescript
const index = await ui.showActionSheet({
  title: 'Choose action',
  options: ['Share', 'Copy', 'Delete'],
  cancelIndex: 2,
});
```

### `setStatusBar(payload): Promise<void>`

Configure the native status bar appearance.

```typescript
await ui.setStatusBar({ style: 'light', hidden: false });
```

### `showKeyboard(): void`

Request the keyboard to appear. Fire-and-forget.

### `hideKeyboard(): void`

Dismiss the keyboard. Fire-and-forget.

### `getKeyboardHeight(): Promise<KeyboardHeightResponse>`

Get the current keyboard height and visibility.

```typescript
const kb = await ui.getKeyboardHeight();
// { height: 336, visible: true }
```

## Event Subscriptions

### `onKeyboardChange(listener): () => void`

Subscribe to keyboard visibility changes.

```typescript
const unsubscribe = ui.onKeyboardChange((info) => {
  console.log(`Keyboard: ${info.visible ? 'visible' : 'hidden'}, height: ${info.height}`);
});
```

## Types

```typescript
interface AlertPayload {
  title: string;
  message: string;
  buttonText?: string;
}

interface ConfirmPayload {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
}

interface ToastPayload {
  message: string;
  duration?: 'short' | 'long';
}

interface ActionSheetPayload {
  title?: string;
  options: string[];
  cancelIndex?: number;
}

interface StatusBarPayload {
  style?: 'default' | 'light' | 'dark';
  hidden?: boolean;
}

interface KeyboardHeightResponse {
  height: number;
  visible: boolean;
}
```
