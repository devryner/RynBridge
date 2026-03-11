---
sidebar_position: 13
---

# Contacts Module API

`@rynbridge/contacts` — Access and manage device contacts.

## Setup

```typescript
import { ContactsModule } from '@rynbridge/contacts';

const contacts = new ContactsModule(bridge);
```

## Methods

### `getAll(): Promise<ContactList>`

Returns all contacts on the device. Requires permission.

```typescript
const { contacts: list } = await contacts.getAll();
// { contacts: [{ id: '1', name: 'Alice', phone: '+1234567890', email: 'alice@example.com' }, ...] }
```

### `getById(payload): Promise<Contact>`

Returns a single contact by ID.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `string` | Yes | Contact identifier |

```typescript
const contact = await contacts.getById({ id: '1' });
// { id: '1', name: 'Alice', phone: '+1234567890', email: 'alice@example.com' }
```

### `search(payload): Promise<ContactList>`

Searches contacts by name, phone, or email.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | `string` | Yes | Search query string |

```typescript
const { contacts: results } = await contacts.search({ query: 'Alice' });
// { contacts: [{ id: '1', name: 'Alice', ... }] }
```

### `create(payload): Promise<Contact>`

Creates a new contact on the device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | `string` | Yes | Contact display name |
| `phone` | `string` | No | Phone number |
| `email` | `string` | No | Email address |

```typescript
const contact = await contacts.create({ name: 'Bob', phone: '+9876543210', email: 'bob@example.com' });
// { id: '2', name: 'Bob', phone: '+9876543210', email: 'bob@example.com' }
```

### `update(payload): Promise<Contact>`

Updates an existing contact.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `string` | Yes | Contact identifier |
| `name` | `string` | No | Updated display name |
| `phone` | `string` | No | Updated phone number |
| `email` | `string` | No | Updated email address |

```typescript
const contact = await contacts.update({ id: '2', phone: '+1112223333' });
// { id: '2', name: 'Bob', phone: '+1112223333', email: 'bob@example.com' }
```

### `delete(payload): Promise<void>`

Deletes a contact from the device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `string` | Yes | Contact identifier |

```typescript
await contacts.delete({ id: '2' });
```

### `requestPermission(): Promise<PermissionResult>`

Requests permission to access device contacts.

```typescript
const { granted } = await contacts.requestPermission();
if (granted) {
  const { contacts: list } = await contacts.getAll();
}
```

## Types

```typescript
interface Contact {
  id: string;
  name: string;
  phone?: string;
  email?: string;
}

interface ContactList {
  contacts: Contact[];
}

interface ContactCreatePayload {
  name: string;
  phone?: string;
  email?: string;
}

interface ContactUpdatePayload {
  id: string;
  name?: string;
  phone?: string;
  email?: string;
}

interface PermissionResult {
  granted: boolean;
}
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `ContactsProvider` | `getAll`, `getById`, `search`, `create`, `update`, `delete`, `requestPermission` |
| Android | `ContactsProvider` | Same as iOS |
