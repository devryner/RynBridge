export interface Calendar {
  id: string;
  title: string;
  color: string | null;
  isReadOnly: boolean;
}

export interface CalendarEvent {
  id: string;
  calendarId: string;
  title: string;
  startDate: string;
  endDate: string;
  location: string | null;
  notes: string | null;
  isAllDay: boolean;
}

export interface GetCalendarsResult {
  calendars: Calendar[];
}

export interface GetEventsPayload {
  calendarId?: string;
  from: string;
  to: string;
}

export interface GetEventsResult {
  events: CalendarEvent[];
}

export interface GetEventPayload {
  id: string;
}

export interface CreateEventPayload {
  calendarId?: string;
  title: string;
  startDate: string;
  endDate: string;
  location?: string;
  notes?: string;
  isAllDay?: boolean;
}

export interface CreateEventResult {
  id: string;
}

export interface UpdateEventPayload {
  id: string;
  title?: string;
  startDate?: string;
  endDate?: string;
  location?: string;
  notes?: string;
  isAllDay?: boolean;
}

export interface DeleteEventPayload {
  id: string;
}

export interface CreateReminderPayload {
  title: string;
  dueDate?: string;
  notes?: string;
}

export interface CreateReminderResult {
  id: string;
}

export interface PermissionResult {
  granted: boolean;
}

export interface PermissionStatus {
  status: 'granted' | 'denied' | 'notDetermined';
}
