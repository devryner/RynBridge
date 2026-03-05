---
sidebar_position: 6
---

# Auth Module API

`@rynbridge/auth` — Authentication with OAuth providers, token management, and auth state observation.

## Setup

```typescript
import { AuthModule } from '@rynbridge/auth';

const auth = new AuthModule(bridge);
```

## Methods

### `login(payload): Promise<LoginResult>`

Initiates login flow via the native provider.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `provider` | `string` | Yes | OAuth provider name (e.g., `'google'`, `'apple'`) |
| `scopes` | `string[]` | No | Requested permission scopes |

```typescript
const result = await auth.login({ provider: 'google', scopes: ['email', 'profile'] });
// { token: '...', refreshToken: '...', expiresAt: '2026-12-31T00:00:00Z', user: { id, email, name, profileImage } }
```

### `logout(): Promise<void>`

Signs out the current user.

```typescript
await auth.logout();
```

### `getToken(): Promise<TokenResult>`

Returns the current auth token, or `null` if not authenticated.

```typescript
const { token, expiresAt } = await auth.getToken();
if (token) {
  console.log('Authenticated until', expiresAt);
}
```

### `refreshToken(): Promise<LoginResult>`

Refreshes the auth token using the stored refresh token.

```typescript
const result = await auth.refreshToken();
console.log('New token:', result.token);
```

### `getUser(): Promise<UserResult>`

Returns the current user profile, or `null` if not authenticated.

```typescript
const { user } = await auth.getUser();
if (user) {
  console.log(user.name, user.email);
}
```

### `onAuthStateChange(listener): () => void`

Subscribes to authentication state changes. Returns an unsubscribe function.

```typescript
const unsub = auth.onAuthStateChange((state) => {
  console.log(state.authenticated, state.user);
});

// Cleanup
unsub();
```

## Types

```typescript
interface AuthUser {
  id: string;
  email: string | null;
  name: string | null;
  profileImage: string | null;
}

interface LoginPayload { provider: string; scopes?: string[] }
interface LoginResult { token: string; refreshToken: string | null; expiresAt: string; user: AuthUser | null }
interface TokenResult { token: string | null; expiresAt: string | null }
interface UserResult { user: AuthUser | null }
interface AuthStateEvent { authenticated: boolean; user: AuthUser | null }
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `AuthProvider` | `login`, `logout`, `getToken`, `refreshToken`, `getUser` |
| Android | `AuthProvider` | Same as iOS |
