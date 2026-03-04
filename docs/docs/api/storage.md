---
sidebar_position: 3
---

# Storage Module API

`@rynbridge/storage` — Key-value store and file system access.

## Setup

```typescript
import { StorageModule } from '@rynbridge/storage';

const storage = new StorageModule(bridge);
```

## Key-Value Store

### `get(key): Promise<StorageGetResponse>`

```typescript
const result = await storage.get({ key: 'user_name' });
// { value: 'Alice', exists: true }
```

### `set(key, value): Promise<void>`

```typescript
await storage.set({ key: 'user_name', value: 'Alice' });
```

### `remove(key): Promise<void>`

```typescript
await storage.remove({ key: 'user_name' });
```

### `clear(): Promise<void>`

```typescript
await storage.clear();
```

### `keys(): Promise<StorageKeysResponse>`

```typescript
const result = await storage.keys();
// { keys: ['user_name', 'theme', 'locale'] }
```

## File System

### `readFile(path, encoding?): Promise<StorageReadFileResponse>`

```typescript
const file = await storage.readFile({ path: '/documents/notes.txt' });
// { content: 'Hello, world!' }
```

### `writeFile(path, content, encoding?): Promise<void>`

```typescript
await storage.writeFile({
  path: '/documents/notes.txt',
  content: 'Updated content',
});
```

### `deleteFile(path): Promise<void>`

```typescript
await storage.deleteFile({ path: '/documents/old.txt' });
```

### `listDir(path): Promise<StorageListDirResponse>`

```typescript
const result = await storage.listDir({ path: '/documents' });
// { files: ['notes.txt', 'images/'] }
```

### `getFileInfo(path): Promise<StorageGetFileInfoResponse>`

```typescript
const info = await storage.getFileInfo({ path: '/documents/notes.txt' });
// { size: 1024, modifiedAt: '2024-01-01T00:00:00Z', isDirectory: false }
```

## Types

```typescript
interface StorageGetResponse {
  value: string | null;
  exists: boolean;
}

interface StorageKeysResponse {
  keys: string[];
}

interface StorageReadFileResponse {
  content: string;
}

interface StorageListDirResponse {
  files: string[];
}

interface StorageGetFileInfoResponse {
  size: number;
  modifiedAt: string;
  isDirectory: boolean;
}
```
