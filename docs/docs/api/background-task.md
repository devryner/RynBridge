---
sidebar_position: 22
---

# Background Task Module API

`@rynbridge/background-task` — Schedule and manage background tasks.

## Setup

```typescript
import { BackgroundTaskModule } from '@rynbridge/background-task';

const backgroundTask = new BackgroundTaskModule(bridge);
```

## Methods

### `schedule(payload): Promise<TaskResult>`

Schedules a background task.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | `string` | Yes | Unique task identifier |
| `type` | `'oneTime' \| 'periodic'` | Yes | Task type |
| `interval` | `number` | No | Repeat interval in minutes (periodic only) |
| `constraints` | `TaskConstraints` | No | Execution constraints |

```typescript
const result = await backgroundTask.schedule({
  taskId: 'sync-data',
  type: 'periodic',
  interval: 60,
  constraints: { requiresNetwork: true },
});
// { taskId: 'sync-data', scheduled: true }
```

### `cancel(payload): Promise<void>`

Cancels a scheduled background task.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | `string` | Yes | Task identifier to cancel |

```typescript
await backgroundTask.cancel({ taskId: 'sync-data' });
```

### `cancelAll(): Promise<void>`

Cancels all scheduled background tasks.

```typescript
await backgroundTask.cancelAll();
```

### `getStatus(payload): Promise<TaskStatus>`

Returns the status of a scheduled task.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | `string` | Yes | Task identifier |

```typescript
const status = await backgroundTask.getStatus({ taskId: 'sync-data' });
// { taskId: 'sync-data', state: 'enqueued' }
```

### `onTaskComplete(listener): () => void`

Subscribes to task completion events.

```typescript
const unsub = backgroundTask.onTaskComplete((event) => {
  console.log(event.taskId, event.success);
});
```

## Types

```typescript
interface SchedulePayload {
  taskId: string;
  type: 'oneTime' | 'periodic';
  interval?: number;
  constraints?: TaskConstraints;
}

interface TaskConstraints {
  requiresNetwork?: boolean;
  requiresCharging?: boolean;
}

interface TaskResult {
  taskId: string;
  scheduled: boolean;
}

interface TaskStatus {
  taskId: string;
  state: 'enqueued' | 'running' | 'completed' | 'cancelled' | 'failed';
}

interface TaskCompleteEvent {
  taskId: string;
  success: boolean;
}
```

## Native Provider

| Platform | Protocol/Interface | Default Provider |
|----------|-------------------|-----------------|
| iOS | `BackgroundTaskProvider` | `DefaultBackgroundTaskProvider` (BGTaskScheduler) |
| Android | `BackgroundTaskProvider` | `DefaultBackgroundTaskProvider` (WorkManager) |
