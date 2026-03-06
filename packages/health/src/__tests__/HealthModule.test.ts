import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { HealthModule } from '../HealthModule.js';

describe('HealthModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let health: HealthModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    health = new HealthModule(bridge);
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

  describe('requestPermission', () => {
    it('sends read and write types', async () => {
      const promise = health.requestPermission({
        readTypes: ['steps', 'heartRate'],
        writeTypes: ['steps'],
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('health');
      expect(sent.action).toBe('requestPermission');
      expect(sent.payload).toEqual({
        readTypes: ['steps', 'heartRate'],
        writeTypes: ['steps'],
      });

      respondSuccess({ granted: true });

      const result = await promise;
      expect(result).toEqual({ granted: true });
    });
  });

  describe('getPermissionStatus', () => {
    it('returns permission status', async () => {
      const promise = health.getPermissionStatus();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('health');
      expect(sent.action).toBe('getPermissionStatus');

      respondSuccess({ status: 'granted' });

      const result = await promise;
      expect(result).toEqual({ status: 'granted' });
    });
  });

  describe('queryData', () => {
    it('queries health records by type and date range', async () => {
      const promise = health.queryData({
        dataType: 'heartRate',
        startDate: '2024-01-01T00:00:00Z',
        endDate: '2024-01-02T00:00:00Z',
        limit: 10,
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('health');
      expect(sent.action).toBe('queryData');
      expect(sent.payload).toEqual({
        dataType: 'heartRate',
        startDate: '2024-01-01T00:00:00Z',
        endDate: '2024-01-02T00:00:00Z',
        limit: 10,
      });

      respondSuccess({
        records: [
          {
            id: 'rec-1',
            dataType: 'heartRate',
            value: 72,
            unit: 'bpm',
            startDate: '2024-01-01T10:00:00Z',
            endDate: '2024-01-01T10:00:00Z',
            sourceName: 'Apple Watch',
          },
        ],
      });

      const result = await promise;
      expect(result.records).toHaveLength(1);
      expect(result.records[0].value).toBe(72);
    });
  });

  describe('writeData', () => {
    it('writes health data', async () => {
      const promise = health.writeData({
        dataType: 'steps',
        value: 1000,
        unit: 'count',
        startDate: '2024-01-01T10:00:00Z',
        endDate: '2024-01-01T11:00:00Z',
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('health');
      expect(sent.action).toBe('writeData');

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('getSteps', () => {
    it('returns step count for date range', async () => {
      const promise = health.getSteps({
        startDate: '2024-01-01T00:00:00Z',
        endDate: '2024-01-02T00:00:00Z',
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('health');
      expect(sent.action).toBe('getSteps');

      respondSuccess({ steps: 8500 });

      const result = await promise;
      expect(result).toEqual({ steps: 8500 });
    });
  });

  describe('isAvailable', () => {
    it('returns availability status', async () => {
      const promise = health.isAvailable();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('health');
      expect(sent.action).toBe('isAvailable');

      respondSuccess({ available: true });

      const result = await promise;
      expect(result).toEqual({ available: true });
    });
  });

  describe('onDataChange', () => {
    it('subscribes to data change events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = health.onDataChange((data) => {
        received.push(data);
      });

      simulateNativeEvent('health', 'dataChange', { dataType: 'steps' });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ dataType: 'steps' });

      unsubscribe();
      simulateNativeEvent('health', 'dataChange', { dataType: 'heartRate' });

      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = health.queryData({
        dataType: 'heartRate',
        startDate: '2024-01-01T00:00:00Z',
        endDate: '2024-01-02T00:00:00Z',
      });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Health data unavailable' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Health data unavailable');
    });
  });
});
