import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { BackgroundTaskModule } from '../BackgroundTaskModule.js';

describe('BackgroundTaskModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let tasks: BackgroundTaskModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    tasks = new BackgroundTaskModule(bridge);
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

  function simulateNativeEvent(module: string, action: string, payload: Record<string, unknown>) {
    const event = JSON.stringify({
      id: 'event-' + Math.random().toString(36).slice(2),
      module,
      action,
      payload,
      version: '1.0.0',
    });
    transport.simulateIncoming(event);
  }

  describe('scheduleTask', () => {
    it('schedules a periodic task', async () => {
      const promise = tasks.scheduleTask({
        taskId: 'sync-data',
        type: 'periodic',
        interval: 900,
        requiresNetwork: true,
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('backgroundTask');
      expect(sent.action).toBe('scheduleTask');
      expect(sent.payload).toEqual({
        taskId: 'sync-data',
        type: 'periodic',
        interval: 900,
        requiresNetwork: true,
      });

      respondSuccess({ taskId: 'sync-data', success: true });

      const result = await promise;
      expect(result).toEqual({ taskId: 'sync-data', success: true });
    });

    it('schedules a one-time task', async () => {
      const promise = tasks.scheduleTask({
        taskId: 'upload-logs',
        type: 'oneTime',
        delay: 60,
        requiresCharging: true,
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({
        taskId: 'upload-logs',
        type: 'oneTime',
        delay: 60,
        requiresCharging: true,
      });

      respondSuccess({ taskId: 'upload-logs', success: true });

      const result = await promise;
      expect(result).toEqual({ taskId: 'upload-logs', success: true });
    });

    it('schedules a connectivity task', async () => {
      const promise = tasks.scheduleTask({
        taskId: 'offline-sync',
        type: 'connectivity',
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({
        taskId: 'offline-sync',
        type: 'connectivity',
      });

      respondSuccess({ taskId: 'offline-sync', success: true });

      const result = await promise;
      expect(result).toEqual({ taskId: 'offline-sync', success: true });
    });
  });

  describe('cancelTask', () => {
    it('cancels a scheduled task', async () => {
      const promise = tasks.cancelTask({ taskId: 'sync-data' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('backgroundTask');
      expect(sent.action).toBe('cancelTask');
      expect(sent.payload).toEqual({ taskId: 'sync-data' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('cancelAllTasks', () => {
    it('cancels all scheduled tasks', async () => {
      const promise = tasks.cancelAllTasks();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('backgroundTask');
      expect(sent.action).toBe('cancelAllTasks');

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('getScheduledTasks', () => {
    it('returns list of scheduled tasks', async () => {
      const promise = tasks.getScheduledTasks();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('backgroundTask');
      expect(sent.action).toBe('getScheduledTasks');

      respondSuccess({
        tasks: [
          {
            taskId: 'sync-data',
            type: 'periodic',
            interval: 900,
            requiresNetwork: true,
            requiresCharging: false,
          },
        ],
      });

      const result = await promise;
      expect(result.tasks).toHaveLength(1);
      expect(result.tasks[0].taskId).toBe('sync-data');
    });
  });

  describe('onTaskExecute', () => {
    it('subscribes to task execute events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = tasks.onTaskExecute((data) => {
        received.push(data);
      });

      simulateNativeEvent('backgroundTask', 'taskExecute', { taskId: 'sync-data' });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ taskId: 'sync-data' });

      unsubscribe();
      simulateNativeEvent('backgroundTask', 'taskExecute', { taskId: 'upload-logs' });

      expect(received).toHaveLength(1);
    });
  });

  describe('completeTask', () => {
    it('sends fire-and-forget with taskId and success', () => {
      tasks.completeTask({ taskId: 'sync-data', success: true });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('backgroundTask');
      expect(sent.action).toBe('completeTask');
      expect(sent.payload).toEqual({ taskId: 'sync-data', success: true });
    });

    it('sends failure completion', () => {
      tasks.completeTask({ taskId: 'upload-logs', success: false });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ taskId: 'upload-logs', success: false });
    });
  });

  describe('requestPermission', () => {
    it('returns permission result', async () => {
      const promise = tasks.requestPermission();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('backgroundTask');
      expect(sent.action).toBe('requestPermission');

      respondSuccess({ granted: true });

      const result = await promise;
      expect(result).toEqual({ granted: true });
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = tasks.scheduleTask({
        taskId: 'sync-data',
        type: 'periodic',
        interval: 900,
      });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Background tasks not supported' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Background tasks not supported');
    });
  });
});
