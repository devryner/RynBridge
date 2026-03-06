import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { CalendarModule } from '../CalendarModule.js';

describe('CalendarModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let calendar: CalendarModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    calendar = new CalendarModule(bridge);
  });

  function respondSuccess(payload: Record<string, unknown> = {}) {
    const sent = JSON.parse(transport.sent[transport.sent.length - 1]);
    const response: BridgeResponse = {
      id: sent.id,
      status: 'success',
      payload,
      error: null,
    };
    transport.simulateIncoming(JSON.stringify(response));
  }

  describe('getCalendars', () => {
    it('returns list of calendars', async () => {
      const promise = calendar.getCalendars();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('calendar');
      expect(sent.action).toBe('getCalendars');

      respondSuccess({ calendars: [{ id: 'cal-1', title: 'Work', color: '#FF0000', isReadOnly: false }] });
      const result = await promise;
      expect(result.calendars).toHaveLength(1);
      expect(result.calendars[0].title).toBe('Work');
    });
  });

  describe('getEvents', () => {
    it('returns events in date range', async () => {
      const promise = calendar.getEvents({ from: '2026-01-01T00:00:00Z', to: '2026-01-31T23:59:59Z' });
      respondSuccess({ events: [{ id: 'evt-1', calendarId: 'cal-1', title: 'Meeting', startDate: '2026-01-15T10:00:00Z', endDate: '2026-01-15T11:00:00Z', isAllDay: false }] });
      const result = await promise;
      expect(result.events).toHaveLength(1);
      expect(result.events[0].title).toBe('Meeting');
    });
  });

  describe('createEvent', () => {
    it('creates an event and returns id', async () => {
      const promise = calendar.createEvent({
        title: 'New Event',
        startDate: '2026-03-01T10:00:00Z',
        endDate: '2026-03-01T11:00:00Z',
      });
      respondSuccess({ id: 'evt-new' });
      const result = await promise;
      expect(result.id).toBe('evt-new');
    });
  });

  describe('deleteEvent', () => {
    it('deletes an event', async () => {
      const promise = calendar.deleteEvent({ id: 'evt-1' });
      respondSuccess();
      await promise;
    });
  });

  describe('createReminder', () => {
    it('creates a reminder and returns id', async () => {
      const promise = calendar.createReminder({ title: 'Remember this' });
      respondSuccess({ id: 'rem-1' });
      const result = await promise;
      expect(result.id).toBe('rem-1');
    });
  });

  describe('requestPermission', () => {
    it('requests calendar permission', async () => {
      const promise = calendar.requestPermission();
      respondSuccess({ granted: true });
      const result = await promise;
      expect(result.granted).toBe(true);
    });
  });

  describe('getPermissionStatus', () => {
    it('returns permission status', async () => {
      const promise = calendar.getPermissionStatus();
      respondSuccess({ status: 'granted' });
      const result = await promise;
      expect(result.status).toBe('granted');
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = calendar.getCalendars();
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Calendar access denied' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Calendar access denied');
    });
  });
});
