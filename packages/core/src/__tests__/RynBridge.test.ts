import { describe, it, expect, vi, beforeEach } from 'vitest';
import { RynBridge } from '../RynBridge.js';
import { MockTransport } from '../transport/MockTransport.js';
import type { BridgeResponse } from '../types.js';

describe('RynBridge', () => {
  let transport: MockTransport;
  let bridge: RynBridge;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000, version: '0.1.0' }, transport);
  });

  describe('call (request-response)', () => {
    it('sends a request and resolves with response payload', async () => {
      const callPromise = bridge.call('device', 'getInfo', { key: 'test' });

      // Transport should have received the serialized request
      expect(transport.sent).toHaveLength(1);
      const sentRequest = JSON.parse(transport.sent[0]);
      expect(sentRequest.module).toBe('device');
      expect(sentRequest.action).toBe('getInfo');
      expect(sentRequest.payload).toEqual({ key: 'test' });

      // Simulate native response
      const response: BridgeResponse = {
        id: sentRequest.id,
        status: 'success',
        payload: { platform: 'ios' },
        error: null,
      };
      transport.simulateIncoming(JSON.stringify(response));

      const result = await callPromise;
      expect(result).toEqual({ platform: 'ios' });
    });

    it('rejects when native responds with error', async () => {
      const callPromise = bridge.call('device', 'crash');

      const sentRequest = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sentRequest.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Something went wrong' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(callPromise).rejects.toThrow('Something went wrong');
    });

    it('times out if no response', async () => {
      vi.useFakeTimers();
      const timeoutBridge = new RynBridge({ timeout: 100 }, transport);
      const callPromise = timeoutBridge.call('device', 'slow');

      vi.advanceTimersByTime(100);

      await expect(callPromise).rejects.toThrow(/timed out/);
      vi.useRealTimers();
    });
  });

  describe('send (fire-and-forget)', () => {
    it('sends a message without waiting for response', () => {
      bridge.send('analytics', 'track', { event: 'click' });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('track');
      expect(sent.payload).toEqual({ event: 'click' });
    });
  });

  describe('on/off (action handlers)', () => {
    it('handles incoming requests with registered handler', async () => {
      const handler = vi.fn().mockResolvedValue({ pong: true });
      bridge.on('ping', handler);

      const request = {
        id: 'incoming-1',
        module: 'core',
        action: 'ping',
        payload: { ts: 123 },
        version: '0.1.0',
      };
      transport.simulateIncoming(JSON.stringify(request));

      // Wait for async handler
      await vi.waitFor(() => {
        expect(handler).toHaveBeenCalledWith({ ts: 123 });
      });

      // Should send response back
      expect(transport.sent).toHaveLength(1);
      const response = JSON.parse(transport.sent[0]);
      expect(response.id).toBe('incoming-1');
      expect(response.status).toBe('success');
      expect(response.payload).toEqual({ pong: true });
    });

    it('removes action handler with off', () => {
      const handler = vi.fn();
      bridge.on('test', handler);
      bridge.off('test');

      // Incoming request for 'test' should not invoke handler
      const request = {
        id: 'incoming-2',
        module: 'core',
        action: 'test',
        payload: {},
        version: '0.1.0',
      };
      transport.simulateIncoming(JSON.stringify(request));

      expect(handler).not.toHaveBeenCalled();
    });
  });

  describe('onEvent/offEvent', () => {
    it('receives events from native via module:action pattern', () => {
      const listener = vi.fn();
      bridge.onEvent('location:update', listener);

      // Simulate an incoming request that has no handler — becomes event
      const request = {
        id: 'evt-1',
        module: 'location',
        action: 'update',
        payload: { lat: 37.5, lng: 127.0 },
        version: '0.1.0',
      };
      transport.simulateIncoming(JSON.stringify(request));

      expect(listener).toHaveBeenCalledWith({ lat: 37.5, lng: 127.0 });
    });

    it('stops receiving events after offEvent', () => {
      const listener = vi.fn();
      bridge.onEvent('location:update', listener);
      bridge.offEvent('location:update', listener);

      const request = {
        id: 'evt-2',
        module: 'location',
        action: 'update',
        payload: {},
        version: '0.1.0',
      };
      transport.simulateIncoming(JSON.stringify(request));

      expect(listener).not.toHaveBeenCalled();
    });
  });

  describe('dispose', () => {
    it('rejects pending calls and prevents new calls', async () => {
      vi.useFakeTimers();
      const callPromise = bridge.call('device', 'info');
      bridge.dispose();

      await expect(callPromise).rejects.toThrow(/disposed/);
      await expect(bridge.call('device', 'info')).rejects.toThrow(/disposed/);
      vi.useRealTimers();
    });

    it('prevents send after dispose', () => {
      bridge.dispose();
      expect(() => bridge.send('m', 'a')).toThrow(/disposed/);
    });
  });

  describe('module registration', () => {
    it('handles requests via registered module', async () => {
      const handler = vi.fn().mockReturnValue({ battery: 100 });

      bridge.register({
        name: 'device',
        version: '0.1.0',
        actions: { getBattery: handler },
      });

      const request = {
        id: 'mod-1',
        module: 'device',
        action: 'getBattery',
        payload: {},
        version: '0.1.0',
      };
      transport.simulateIncoming(JSON.stringify(request));

      await vi.waitFor(() => {
        expect(handler).toHaveBeenCalled();
      });

      expect(transport.sent).toHaveLength(1);
      const response = JSON.parse(transport.sent[0]);
      expect(response.status).toBe('success');
      expect(response.payload).toEqual({ battery: 100 });
    });
  });
});
