import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { DeviceModule } from '../DeviceModule.js';

describe('DeviceModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let device: DeviceModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    device = new DeviceModule(bridge);
  });

  describe('getInfo', () => {
    it('sends correct module and action', async () => {
      const promise = device.getInfo();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('getInfo');
      expect(sent.payload).toEqual({});

      const response: BridgeResponse = {
        id: sent.id,
        status: 'success',
        payload: { platform: 'ios', osVersion: '17.0', model: 'iPhone 15', appVersion: '1.0.0' },
        error: null,
      };
      transport.simulateIncoming(JSON.stringify(response));

      const result = await promise;
      expect(result).toEqual({
        platform: 'ios',
        osVersion: '17.0',
        model: 'iPhone 15',
        appVersion: '1.0.0',
      });
    });
  });

  describe('getBattery', () => {
    it('sends correct module and action', async () => {
      const promise = device.getBattery();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('getBattery');

      const response: BridgeResponse = {
        id: sent.id,
        status: 'success',
        payload: { level: 85, isCharging: true },
        error: null,
      };
      transport.simulateIncoming(JSON.stringify(response));

      const result = await promise;
      expect(result).toEqual({ level: 85, isCharging: true });
    });
  });

  describe('getScreen', () => {
    it('sends correct module and action', async () => {
      const promise = device.getScreen();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('getScreen');

      const response: BridgeResponse = {
        id: sent.id,
        status: 'success',
        payload: { width: 390, height: 844, scale: 3, orientation: 'portrait' },
        error: null,
      };
      transport.simulateIncoming(JSON.stringify(response));

      const result = await promise;
      expect(result).toEqual({ width: 390, height: 844, scale: 3, orientation: 'portrait' });
    });
  });

  describe('vibrate', () => {
    it('sends fire-and-forget without payload', () => {
      device.vibrate();

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('vibrate');
      expect(sent.payload).toEqual({});
    });

    it('sends fire-and-forget with pattern', () => {
      device.vibrate({ pattern: [100, 50, 100] });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('vibrate');
      expect(sent.payload).toEqual({ pattern: [100, 50, 100] });
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = device.getInfo();

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Device info unavailable' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Device info unavailable');
    });
  });
});
