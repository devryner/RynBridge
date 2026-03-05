---
sidebar_position: 10
---

# Crypto Module API

`@rynbridge/crypto` — Key generation, key exchange, authenticated encryption, and key rotation.

## Setup

```typescript
import { CryptoModule } from '@rynbridge/crypto';

const crypto = new CryptoModule(bridge);
```

## Methods

### `generateKeyPair(): Promise<KeyPairResult>`

Generates a new asymmetric key pair. Returns the public key (base64).

```typescript
const { publicKey } = await crypto.generateKeyPair();
// Send publicKey to the remote party
```

### `performKeyExchange(payload): Promise<KeyExchangeResult>`

Performs a Diffie-Hellman key exchange to establish a shared session key.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `remotePublicKey` | `string` | Yes | Remote party's public key (base64) |

```typescript
const { sessionEstablished } = await crypto.performKeyExchange({ remotePublicKey: '...' });
```

### `encrypt(payload): Promise<EncryptResult>`

Encrypts data using the established session key (AES-GCM).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `data` | `string` | Yes | Plaintext to encrypt |
| `associatedData` | `string` | No | Additional authenticated data (AAD) |

```typescript
const { ciphertext, iv, tag } = await crypto.encrypt({ data: 'secret message' });
```

### `decrypt(payload): Promise<DecryptResult>`

Decrypts ciphertext using the established session key.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ciphertext` | `string` | Yes | Encrypted data (base64) |
| `iv` | `string` | Yes | Initialization vector (base64) |
| `tag` | `string` | Yes | Authentication tag (base64) |
| `associatedData` | `string` | No | Additional authenticated data (AAD) |

```typescript
const { plaintext } = await crypto.decrypt({ ciphertext, iv, tag });
```

### `getStatus(): Promise<CryptoStatus>`

Returns the current crypto module status.

```typescript
const status = await crypto.getStatus();
// { initialized: true, keyCreatedAt: '2026-01-01T00:00:00Z', algorithm: 'X25519+AES-256-GCM' }
```

### `rotateKeys(): Promise<KeyPairResult>`

Rotates the key pair and returns the new public key.

```typescript
const { publicKey } = await crypto.rotateKeys();
// Re-exchange keys with remote party
```

## Types

```typescript
interface KeyPairResult { publicKey: string }
interface KeyExchangePayload { remotePublicKey: string }
interface KeyExchangeResult { sessionEstablished: boolean }
interface EncryptPayload { data: string; associatedData?: string }
interface EncryptResult { ciphertext: string; iv: string; tag: string }
interface DecryptPayload { ciphertext: string; iv: string; tag: string; associatedData?: string }
interface DecryptResult { plaintext: string }
interface CryptoStatus { initialized: boolean; keyCreatedAt: string | null; algorithm: string }
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `CryptoProvider` | `generateKeyPair`, `performKeyExchange`, `encrypt`, `decrypt`, `getStatus`, `rotateKeys` |
| Android | `CryptoProvider` | Same as iOS |
