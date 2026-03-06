import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { BluetoothModule } from '../BluetoothModule.js';

describe('BluetoothModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let bt: BluetoothModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    bt = new BluetoothModule(bridge);
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

  describe('startScan', () => {
    it('sends correct module and action without payload', async () => {
      const promise = bt.startScan();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('startScan');
      expect(sent.payload).toEqual({});

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });

    it('sends serviceUUIDs filter', async () => {
      const promise = bt.startScan({ serviceUUIDs: ['180D'] });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ serviceUUIDs: ['180D'] });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('stopScan', () => {
    it('sends fire-and-forget', () => {
      bt.stopScan();

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('stopScan');
      expect(sent.payload).toEqual({});
    });
  });

  describe('onDeviceFound', () => {
    it('subscribes to device found events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = bt.onDeviceFound((data) => {
        received.push(data);
      });

      simulateNativeEvent('bluetooth', 'deviceFound', {
        deviceId: 'AA:BB:CC:DD:EE:FF',
        name: 'Heart Rate Monitor',
        rssi: -65,
        serviceUUIDs: ['180D'],
      });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({
        deviceId: 'AA:BB:CC:DD:EE:FF',
        name: 'Heart Rate Monitor',
        rssi: -65,
        serviceUUIDs: ['180D'],
      });

      unsubscribe();
      simulateNativeEvent('bluetooth', 'deviceFound', {
        deviceId: 'FF:EE:DD:CC:BB:AA',
        name: null,
        rssi: -80,
        serviceUUIDs: [],
      });

      expect(received).toHaveLength(1);
    });
  });

  describe('connect', () => {
    it('sends deviceId and returns result', async () => {
      const promise = bt.connect({ deviceId: 'AA:BB:CC:DD:EE:FF' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('connect');
      expect(sent.payload).toEqual({ deviceId: 'AA:BB:CC:DD:EE:FF' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('disconnect', () => {
    it('sends deviceId and returns result', async () => {
      const promise = bt.disconnect({ deviceId: 'AA:BB:CC:DD:EE:FF' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('disconnect');
      expect(sent.payload).toEqual({ deviceId: 'AA:BB:CC:DD:EE:FF' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('getServices', () => {
    it('returns services with characteristics', async () => {
      const promise = bt.getServices({ deviceId: 'AA:BB:CC:DD:EE:FF' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('getServices');

      respondSuccess({
        services: [
          {
            uuid: '180D',
            characteristics: [
              { uuid: '2A37', properties: ['read', 'notify'] },
            ],
          },
        ],
      });

      const result = await promise;
      expect(result.services).toHaveLength(1);
      expect(result.services[0].uuid).toBe('180D');
    });
  });

  describe('readCharacteristic', () => {
    it('reads characteristic value', async () => {
      const promise = bt.readCharacteristic({
        deviceId: 'AA:BB:CC:DD:EE:FF',
        serviceUUID: '180D',
        characteristicUUID: '2A37',
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('readCharacteristic');

      respondSuccess({ value: 'AQID' });

      const result = await promise;
      expect(result).toEqual({ value: 'AQID' });
    });
  });

  describe('writeCharacteristic', () => {
    it('writes characteristic value', async () => {
      const promise = bt.writeCharacteristic({
        deviceId: 'AA:BB:CC:DD:EE:FF',
        serviceUUID: '180D',
        characteristicUUID: '2A37',
        value: 'AQID',
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('writeCharacteristic');

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('onCharacteristicChange', () => {
    it('subscribes to characteristic change events', () => {
      const received: unknown[] = [];
      const unsubscribe = bt.onCharacteristicChange((data) => {
        received.push(data);
      });

      simulateNativeEvent('bluetooth', 'characteristicChange', {
        deviceId: 'AA:BB:CC:DD:EE:FF',
        serviceUUID: '180D',
        characteristicUUID: '2A37',
        value: 'AQID',
      });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({
        deviceId: 'AA:BB:CC:DD:EE:FF',
        serviceUUID: '180D',
        characteristicUUID: '2A37',
        value: 'AQID',
      });

      unsubscribe();
      simulateNativeEvent('bluetooth', 'characteristicChange', {
        deviceId: 'AA:BB:CC:DD:EE:FF',
        serviceUUID: '180D',
        characteristicUUID: '2A37',
        value: 'BAID',
      });

      expect(received).toHaveLength(1);
    });
  });

  describe('requestPermission', () => {
    it('returns permission result', async () => {
      const promise = bt.requestPermission();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('requestPermission');

      respondSuccess({ granted: true });

      const result = await promise;
      expect(result).toEqual({ granted: true });
    });
  });

  describe('getState', () => {
    it('returns bluetooth state', async () => {
      const promise = bt.getState();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('bluetooth');
      expect(sent.action).toBe('getState');

      respondSuccess({ state: 'poweredOn' });

      const result = await promise;
      expect(result).toEqual({ state: 'poweredOn' });
    });
  });

  describe('onStateChange', () => {
    it('subscribes to state change events', () => {
      const received: unknown[] = [];
      const unsubscribe = bt.onStateChange((data) => {
        received.push(data);
      });

      simulateNativeEvent('bluetooth', 'stateChange', { state: 'poweredOff' });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ state: 'poweredOff' });

      unsubscribe();
      simulateNativeEvent('bluetooth', 'stateChange', { state: 'poweredOn' });

      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = bt.connect({ deviceId: 'AA:BB:CC:DD:EE:FF' });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Bluetooth unavailable' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Bluetooth unavailable');
    });
  });
});
