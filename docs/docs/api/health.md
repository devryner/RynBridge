---
sidebar_position: 21
---

# Health Module API

`@rynbridge/health` — Access health and fitness data from HealthKit (iOS) and Health Connect (Android).

## Setup

```typescript
import { HealthModule } from '@rynbridge/health';

const health = new HealthModule(bridge);
```

## Methods

### `requestPermission(payload): Promise<PermissionResult>`

Requests permission to read/write health data.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `readTypes` | `string[]` | Yes | Health data types to read (e.g., `['steps', 'heartRate']`) |
| `writeTypes` | `string[]` | No | Health data types to write |

```typescript
const { granted } = await health.requestPermission({
  readTypes: ['steps', 'heartRate'],
  writeTypes: ['steps'],
});
```

### `queryData(payload): Promise<HealthDataResult>`

Queries health data for a given type and date range.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `type` | `string` | Yes | Health data type |
| `startDate` | `string` | Yes | ISO 8601 start date |
| `endDate` | `string` | Yes | ISO 8601 end date |

```typescript
const result = await health.queryData({
  type: 'steps',
  startDate: '2026-03-01T00:00:00Z',
  endDate: '2026-03-11T00:00:00Z',
});
// { records: [{ value: 8500, startDate: '...', endDate: '...' }] }
```

### `writeData(payload): Promise<void>`

Writes a health data record.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `type` | `string` | Yes | Health data type |
| `value` | `number` | Yes | Data value |
| `startDate` | `string` | Yes | ISO 8601 start date |
| `endDate` | `string` | Yes | ISO 8601 end date |

```typescript
await health.writeData({
  type: 'steps',
  value: 1000,
  startDate: '2026-03-11T09:00:00Z',
  endDate: '2026-03-11T10:00:00Z',
});
```

### `isAvailable(): Promise<AvailabilityResult>`

Checks whether health data is available on the device.

```typescript
const { available } = await health.isAvailable();
```

## Types

```typescript
interface HealthPermissionPayload {
  readTypes: string[];
  writeTypes?: string[];
}

interface PermissionResult {
  granted: boolean;
}

interface QueryDataPayload {
  type: string;
  startDate: string;
  endDate: string;
}

interface HealthRecord {
  value: number;
  startDate: string;
  endDate: string;
}

interface HealthDataResult {
  records: HealthRecord[];
}

interface WriteDataPayload {
  type: string;
  value: number;
  startDate: string;
  endDate: string;
}

interface AvailabilityResult {
  available: boolean;
}
```

## Native Provider

| Platform | Protocol/Interface | Default Provider |
|----------|-------------------|-----------------|
| iOS | `HealthProvider` | `DefaultHealthProvider` (HealthKit) |
| Android | `HealthProvider` | `DefaultHealthProvider` (Health Connect) |
