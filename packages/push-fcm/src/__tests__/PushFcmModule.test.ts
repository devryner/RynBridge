import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { PushFcmModule } from '../PushFcmModule.js';

describe('PushFcmModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let fcm: PushFcmModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    fcm = new PushFcmModule(bridge);
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

  describe('getToken', () => {
    it('sends correct module and action and returns FCM token', async () => {
      const promise = fcm.getToken();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('push-fcm');
      expect(sent.action).toBe('getToken');
      respondSuccess({ token: 'fcm-token-abc123' });
      const result = await promise;
      expect(result.token).toBe('fcm-token-abc123');
    });
  });

  describe('deleteToken', () => {
    it('sends correct module and action', async () => {
      const promise = fcm.deleteToken();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('push-fcm');
      expect(sent.action).toBe('deleteToken');
      respondSuccess();
      await promise;
    });
  });

  describe('subscribeToTopic', () => {
    it('sends topic in payload', async () => {
      const promise = fcm.subscribeToTopic('news');
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('push-fcm');
      expect(sent.action).toBe('subscribeToTopic');
      expect(sent.payload).toEqual({ topic: 'news' });
      respondSuccess();
      await promise;
    });
  });

  describe('unsubscribeFromTopic', () => {
    it('sends topic in payload', async () => {
      const promise = fcm.unsubscribeFromTopic('news');
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('push-fcm');
      expect(sent.action).toBe('unsubscribeFromTopic');
      expect(sent.payload).toEqual({ topic: 'news' });
      respondSuccess();
      await promise;
    });
  });

  describe('getAutoInitEnabled', () => {
    it('returns auto-init status', async () => {
      const promise = fcm.getAutoInitEnabled();
      respondSuccess({ enabled: true });
      const result = await promise;
      expect(result.enabled).toBe(true);
    });
  });

  describe('setAutoInitEnabled', () => {
    it('sends enabled flag in payload', async () => {
      const promise = fcm.setAutoInitEnabled(false);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('push-fcm');
      expect(sent.action).toBe('setAutoInitEnabled');
      expect(sent.payload).toEqual({ enabled: false });
      respondSuccess();
      await promise;
    });
  });

  describe('onTokenRefresh', () => {
    it('subscribes to token refresh events and returns unsubscribe', () => {
      const received: unknown[] = [];
      const unsub = fcm.onTokenRefresh((data) => received.push(data));

      simulateNativeEvent('push-fcm', 'tokenRefresh', { token: 'new-fcm-token' });
      expect(received).toHaveLength(1);
      expect((received[0] as any).token).toBe('new-fcm-token');

      unsub();
      simulateNativeEvent('push-fcm', 'tokenRefresh', { token: 'another-token' });
      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = fcm.getToken();
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'FCM service unavailable' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('FCM service unavailable');
    });
  });
});
