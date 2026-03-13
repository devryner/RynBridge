import { RynBridge } from '@rynbridge/core';
import type {
  GetCalendarsResult,
  GetEventsPayload,
  GetEventsResult,
  GetEventPayload,
  CalendarEvent,
  CreateEventPayload,
  CreateEventResult,
  UpdateEventPayload,
  DeleteEventPayload,
  CreateReminderPayload,
  CreateReminderResult,
  PermissionResult,
  PermissionStatus,
} from './types.js';

const MODULE = 'calendar';

export class CalendarModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async getCalendars(): Promise<GetCalendarsResult> {
    const result = await this.bridge.call(MODULE, 'getCalendars');
    return result as unknown as GetCalendarsResult;
  }

  async getEvents(payload: GetEventsPayload): Promise<GetEventsResult> {
    const result = await this.bridge.call(MODULE, 'getEvents', payload as unknown as Record<string, unknown>);
    return result as unknown as GetEventsResult;
  }

  async getEvent(payload: GetEventPayload): Promise<CalendarEvent> {
    const result = await this.bridge.call(MODULE, 'getEvent', payload as unknown as Record<string, unknown>);
    return result as unknown as CalendarEvent;
  }

  async createEvent(payload: CreateEventPayload): Promise<CreateEventResult> {
    const result = await this.bridge.call(MODULE, 'createEvent', payload as unknown as Record<string, unknown>);
    return result as unknown as CreateEventResult;
  }

  async updateEvent(payload: UpdateEventPayload): Promise<void> {
    await this.bridge.call(MODULE, 'updateEvent', payload as unknown as Record<string, unknown>);
  }

  async deleteEvent(payload: DeleteEventPayload): Promise<void> {
    await this.bridge.call(MODULE, 'deleteEvent', payload as unknown as Record<string, unknown>);
  }

  async createReminder(payload: CreateReminderPayload): Promise<CreateReminderResult> {
    const result = await this.bridge.call(MODULE, 'createReminder', payload as unknown as Record<string, unknown>);
    return result as unknown as CreateReminderResult;
  }

  async requestPermission(): Promise<PermissionResult> {
    const result = await this.bridge.call(MODULE, 'requestPermission');
    return result as unknown as PermissionResult;
  }

  async getPermissionStatus(): Promise<PermissionStatus> {
    const result = await this.bridge.call(MODULE, 'getPermissionStatus');
    return result as unknown as PermissionStatus;
  }
}
