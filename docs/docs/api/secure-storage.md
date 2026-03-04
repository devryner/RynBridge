---
sidebar_position: 4
---

# Secure Storage Module API

`@rynbridge/secure-storage` — Encrypted key-value storage using platform keychain/keystore.

## Setup

```typescript
import { SecureStorageModule } from '@rynbridge/secure-storage';

const secureStorage = new SecureStorageModule(bridge);
```

## Methods

### `get(key): Promise<SecureStorageGetResponse>`

Retrieve a value from secure storage.

```typescript
const result = await secureStorage.get({ key: 'auth_token' });
// { value: 'eyJhbGciOiJ...', exists: true }
```

### `set(key, value): Promise<void>`

Store a value in secure storage.

```typescript
await secureStorage.set({ key: 'auth_token', value: 'eyJhbGciOiJ...' });
```

### `has(key): Promise<SecureStorageHasResponse>`

Check if a key exists.

```typescript
const result = await secureStorage.has({ key: 'auth_token' });
// { exists: true }
```

### `remove(key): Promise<void>`

Remove a value from secure storage.

```typescript
await secureStorage.remove({ key: 'auth_token' });
```

## Platform Storage

| Platform | Backend |
|----------|---------|
| iOS | Keychain Services |
| Android | Android Keystore |

## Types

```typescript
interface SecureStorageGetResponse {
  value: string | null;
  exists: boolean;
}

interface SecureStorageHasResponse {
  exists: boolean;
}
```
