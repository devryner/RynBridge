---
sidebar_position: 14
---

# Calendar Module API

`@rynbridge/calendar` — Access and manage device calendar events.

## Setup

```typescript
import { CalendarModule } from '@rynbridge/calendar';

const calendar = new CalendarModule(bridge);
```

## Methods

### `getEvents(payload): Promise<EventList>`

Returns calendar events within a date range.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `startDate` | `string` | Yes | ISO 8601 start date |
| `endDate` | `string` | Yes | ISO 8601 end date |
| `calendarId` | `string` | No | Filter by specific calendar |

```typescript
const { events } = await calendar.getEvents({
  startDate: '2026-03-01T00:00:00Z',
  endDate: '2026-03-31T23:59:59Z',
});
// { events: [{ id: '1', title: 'Team Standup', startDate: '...', endDate: '...', calendarId: 'work' }, ...] }
```

### `getEventById(payload): Promise<CalendarEvent>`

Returns a single calendar event by ID.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `string` | Yes | Event identifier |

```typescript
const event = await calendar.getEventById({ id: '1' });
// { id: '1', title: 'Team Standup', startDate: '2026-03-11T09:00:00Z', endDate: '2026-03-11T09:30:00Z', calendarId: 'work' }
```

### `createEvent(payload): Promise<CalendarEvent>`

Creates a new calendar event.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | `string` | Yes | Event title |
| `startDate` | `string` | Yes | ISO 8601 start date |
| `endDate` | `string` | Yes | ISO 8601 end date |
| `location` | `string` | No | Event location |
| `notes` | `string` | No | Event notes or description |

```typescript
const event = await calendar.createEvent({
  title: 'Launch Party',
  startDate: '2026-04-01T18:00:00Z',
  endDate: '2026-04-01T21:00:00Z',
  location: 'HQ Rooftop',
  notes: 'Celebrate the v1.0 release!',
});
// { id: '2', title: 'Launch Party', startDate: '...', endDate: '...', location: 'HQ Rooftop', notes: '...', calendarId: 'default' }
```

### `updateEvent(payload): Promise<CalendarEvent>`

Updates an existing calendar event.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `string` | Yes | Event identifier |
| `title` | `string` | No | Updated event title |
| `startDate` | `string` | No | Updated ISO 8601 start date |
| `endDate` | `string` | No | Updated ISO 8601 end date |
| `location` | `string` | No | Updated event location |
| `notes` | `string` | No | Updated event notes |

```typescript
const event = await calendar.updateEvent({ id: '2', location: 'Main Office Lobby' });
// { id: '2', title: 'Launch Party', ..., location: 'Main Office Lobby' }
```

### `deleteEvent(payload): Promise<void>`

Deletes a calendar event.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `string` | Yes | Event identifier |

```typescript
await calendar.deleteEvent({ id: '2' });
```

### `getCalendars(): Promise<CalendarList>`

Returns all calendars available on the device.

```typescript
const { calendars } = await calendar.getCalendars();
// { calendars: [{ id: 'work', title: 'Work', color: '#007AFF' }, { id: 'personal', title: 'Personal', color: '#FF3B30' }] }
```

### `requestPermission(): Promise<PermissionResult>`

Requests permission to access the device calendar.

```typescript
const { granted } = await calendar.requestPermission();
if (granted) {
  const { events } = await calendar.getEvents({
    startDate: '2026-03-01T00:00:00Z',
    endDate: '2026-03-31T23:59:59Z',
  });
}
```

## Types

```typescript
interface CalendarEvent {
  id: string;
  title: string;
  startDate: string;
  endDate: string;
  location?: string;
  notes?: string;
  calendarId: string;
}

interface EventList {
  events: CalendarEvent[];
}

interface Calendar {
  id: string;
  title: string;
  color?: string;
}

interface CalendarList {
  calendars: Calendar[];
}

interface CreateEventPayload {
  title: string;
  startDate: string;
  endDate: string;
  location?: string;
  notes?: string;
}

interface UpdateEventPayload {
  id: string;
  title?: string;
  startDate?: string;
  endDate?: string;
  location?: string;
  notes?: string;
}

interface PermissionResult {
  granted: boolean;
}
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `CalendarProvider` | `getEvents`, `getEventById`, `createEvent`, `updateEvent`, `deleteEvent`, `getCalendars`, `requestPermission` |
| Android | `CalendarProvider` | Same as iOS |
