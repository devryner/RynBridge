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

  describe('getInfo', () => {
    it('sends correct module and action', async () => {
      const promise = device.getInfo();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('getInfo');
      expect(sent.payload).toEqual({});

      respondSuccess({ platform: 'ios', osVersion: '17.0', model: 'iPhone 15', appVersion: '1.0.0' });

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

      respondSuccess({ level: 85, isCharging: true });

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

      respondSuccess({ width: 390, height: 844, scale: 3, orientation: 'portrait' });

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

  describe('capturePhoto', () => {
    it('sends correct module and action with default payload', async () => {
      const promise = device.capturePhoto();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('capturePhoto');
      expect(sent.payload).toEqual({});

      respondSuccess({ imageBase64: 'abc123', width: 1920, height: 1080 });

      const result = await promise;
      expect(result).toEqual({ imageBase64: 'abc123', width: 1920, height: 1080 });
    });

    it('sends quality and camera options', async () => {
      const promise = device.capturePhoto({ quality: 0.8, camera: 'front' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ quality: 0.8, camera: 'front' });

      respondSuccess({ imageBase64: 'xyz', width: 640, height: 480 });

      const result = await promise;
      expect(result).toEqual({ imageBase64: 'xyz', width: 640, height: 480 });
    });
  });

  describe('getLocation', () => {
    it('returns location info', async () => {
      const promise = device.getLocation();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('getLocation');
      expect(sent.payload).toEqual({});

      respondSuccess({ latitude: 37.5665, longitude: 126.978, accuracy: 10 });

      const result = await promise;
      expect(result).toEqual({ latitude: 37.5665, longitude: 126.978, accuracy: 10 });
    });
  });

  describe('authenticate', () => {
    it('sends reason and returns success', async () => {
      const promise = device.authenticate({ reason: 'Confirm payment' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('device');
      expect(sent.action).toBe('authenticate');
      expect(sent.payload).toEqual({ reason: 'Confirm payment' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });

    it('returns failure on denied authentication', async () => {
      const promise = device.authenticate({ reason: 'Login' });
      respondSuccess({ success: false });

      const result = await promise;
      expect(result).toEqual({ success: false });
    });
  });

  describe('onLocationChange', () => {
    it('subscribes to location events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = device.onLocationChange((data) => {
        received.push(data);
      });

      simulateNativeEvent('device', 'locationChange', { latitude: 37.5, longitude: 127.0, accuracy: 5 });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ latitude: 37.5, longitude: 127.0, accuracy: 5 });

      unsubscribe();
      simulateNativeEvent('device', 'locationChange', { latitude: 38.0, longitude: 128.0, accuracy: 3 });

      expect(received).toHaveLength(1);
    });
  });

  describe('onBatteryChange', () => {
    it('subscribes to battery events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = device.onBatteryChange((data) => {
        received.push(data);
      });

      simulateNativeEvent('device', 'batteryChange', { level: 75, isCharging: false });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ level: 75, isCharging: false });

      unsubscribe();
      simulateNativeEvent('device', 'batteryChange', { level: 50, isCharging: true });

      expect(received).toHaveLength(1);
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
