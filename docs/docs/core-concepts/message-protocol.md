---
sidebar_position: 2
---

# Message Protocol

All communication between web and native uses a JSON message protocol with UUID correlation IDs.

## Request Format

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "module": "device",
  "action": "getInfo",
  "payload": {},
  "version": "1.0.0"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | UUID v4 correlation ID |
| `module` | `string` | Target module name |
| `action` | `string` | Action to invoke |
| `payload` | `object` | Action-specific parameters |
| `version` | `string` | Semantic version for negotiation |

## Response Format

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "success",
  "payload": {
    "platform": "ios",
    "osVersion": "17.0",
    "model": "iPhone 15",
    "appVersion": "1.0.0"
  },
  "error": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Matches request correlation ID |
| `status` | `"success" \| "error"` | Result status |
| `payload` | `object` | Response data |
| `error` | `BridgeError \| null` | Error details if status is error |

## Error Format

```json
{
  "code": "TIMEOUT",
  "message": "Request timed out after 30000ms",
  "details": {}
}
```

### Error Codes

| Code | Description |
|------|-------------|
| `TIMEOUT` | Request exceeded timeout |
| `MODULE_NOT_FOUND` | Target module not registered |
| `ACTION_NOT_FOUND` | Action not found in module |
| `INVALID_MESSAGE` | Malformed message |
| `SERIALIZATION_ERROR` | JSON parse/stringify failure |
| `TRANSPORT_ERROR` | Transport layer failure |
| `VERSION_MISMATCH` | Incompatible SDK versions |
| `UNKNOWN` | Unclassified error |

## Contract Schemas

JSON Schema definitions in `contracts/` are the source of truth. Each module has `<action>.request.schema.json` and `<action>.response.schema.json` files.

Use the CLI to generate typed code from contracts:

```bash
npx rynbridge generate --target all
```
