import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { PushModule } from '../PushModule.js';

describe('PushModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let push: PushModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    push = new PushModule(bridge);
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

  describe('register', () => {
    it('sends correct module and action and returns registration', async () => {
      const promise = push.register();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('push');
      expect(sent.action).toBe('register');
      respondSuccess({ token: 'fcm-token-123', platform: 'ios' });
      const result = await promise;
      expect(result.token).toBe('fcm-token-123');
      expect(result.platform).toBe('ios');
    });
  });

  describe('unregister', () => {
    it('sends correct module and action', async () => {
      const promise = push.unregister();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('push');
      expect(sent.action).toBe('unregister');
      respondSuccess();
      await promise;
    });
  });

  describe('getToken', () => {
    it('returns push token', async () => {
      const promise = push.getToken();
      respondSuccess({ token: 'tok-abc' });
      const result = await promise;
      expect(result.token).toBe('tok-abc');
    });

    it('returns null token when not registered', async () => {
      const promise = push.getToken();
      respondSuccess({ token: null });
      const result = await promise;
      expect(result.token).toBeNull();
    });
  });

  describe('requestPermission', () => {
    it('returns permission result', async () => {
      const promise = push.requestPermission();
      respondSuccess({ granted: true });
      const result = await promise;
      expect(result.granted).toBe(true);
    });
  });

  describe('getPermissionStatus', () => {
    it('returns permission status', async () => {
      const promise = push.getPermissionStatus();
      respondSuccess({ status: 'granted' });
      const result = await promise;
      expect(result.status).toBe('granted');
    });
  });

  describe('onNotification', () => {
    it('subscribes to notification events and returns unsubscribe', () => {
      const received: unknown[] = [];
      const unsub = push.onNotification((data) => received.push(data));

      simulateNativeEvent('push', 'notification', { title: 'Hello', body: 'World', data: { key: 'val' } });
      expect(received).toHaveLength(1);
      expect((received[0] as any).title).toBe('Hello');

      unsub();
      simulateNativeEvent('push', 'notification', { title: 'Again', body: null, data: null });
      expect(received).toHaveLength(1);
    });
  });

  describe('onTokenRefresh', () => {
    it('subscribes to token refresh events', () => {
      const received: unknown[] = [];
      const unsub = push.onTokenRefresh((data) => received.push(data));

      simulateNativeEvent('push', 'tokenRefresh', { token: 'new-token' });
      expect(received).toHaveLength(1);
      expect((received[0] as any).token).toBe('new-token');

      unsub();
    });
  });

  describe('getInitialNotification', () => {
    it('returns notification when app opened from push', async () => {
      const promise = push.getInitialNotification();
      respondSuccess({ title: 'Welcome', body: 'Tap to open', data: { screen: 'home' } });
      const result = await promise;
      expect(result).not.toBeNull();
      expect(result!.title).toBe('Welcome');
      expect(result!.data).toEqual({ screen: 'home' });
    });

    it('returns null when app was not opened from push', async () => {
      const promise = push.getInitialNotification();
      respondSuccess({ title: null, body: null, data: null });
      const result = await promise;
      expect(result).toBeNull();
    });
  });

  describe('onNotificationOpened', () => {
    it('subscribes to notification opened events and returns unsubscribe', () => {
      const received: unknown[] = [];
      const unsub = push.onNotificationOpened((data) => received.push(data));

      simulateNativeEvent('push', 'notificationOpened', { title: 'Tapped', body: 'You tapped this', data: { id: '123' } });
      expect(received).toHaveLength(1);
      expect((received[0] as any).title).toBe('Tapped');

      unsub();
      simulateNativeEvent('push', 'notificationOpened', { title: 'Again', body: null, data: null });
      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = push.register();
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Push registration failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Push registration failed');
    });
  });
});
