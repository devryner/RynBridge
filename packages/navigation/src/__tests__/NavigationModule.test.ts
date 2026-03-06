import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { NavigationModule } from '../NavigationModule.js';

describe('NavigationModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let navigation: NavigationModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    navigation = new NavigationModule(bridge);
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

  describe('push', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = navigation.push({ screen: 'ProfileScreen', params: { userId: '123' } });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('push');
      expect(sent.payload).toEqual({ screen: 'ProfileScreen', params: { userId: '123' } });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('pop', () => {
    it('sends correct module and action', async () => {
      const promise = navigation.pop();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('pop');
      expect(sent.payload).toEqual({});

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('popToRoot', () => {
    it('sends correct module and action', async () => {
      const promise = navigation.popToRoot();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('popToRoot');
      expect(sent.payload).toEqual({});

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('present', () => {
    it('sends correct module, action, and payload with style', async () => {
      const promise = navigation.present({ screen: 'SettingsScreen', style: 'pageSheet', params: { tab: 'general' } });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('present');
      expect(sent.payload).toEqual({ screen: 'SettingsScreen', style: 'pageSheet', params: { tab: 'general' } });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('dismiss', () => {
    it('sends correct module and action', async () => {
      const promise = navigation.dismiss();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('dismiss');
      expect(sent.payload).toEqual({});

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('openURL', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = navigation.openURL({ url: 'https://example.com' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('openURL');
      expect(sent.payload).toEqual({ url: 'https://example.com' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('canOpenURL', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = navigation.canOpenURL({ url: 'myapp://deep/link' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('canOpenURL');
      expect(sent.payload).toEqual({ url: 'myapp://deep/link' });

      respondSuccess({ canOpen: true });

      const result = await promise;
      expect(result).toEqual({ canOpen: true });
    });

    it('returns false when URL cannot be opened', async () => {
      const promise = navigation.canOpenURL({ url: 'unknown://scheme' });
      respondSuccess({ canOpen: false });

      const result = await promise;
      expect(result).toEqual({ canOpen: false });
    });
  });

  describe('getInitialURL', () => {
    it('returns initial URL when available', async () => {
      const promise = navigation.getInitialURL();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('getInitialURL');
      expect(sent.payload).toEqual({});

      respondSuccess({ url: 'myapp://welcome' });

      const result = await promise;
      expect(result).toEqual({ url: 'myapp://welcome' });
    });

    it('returns null when no initial URL', async () => {
      const promise = navigation.getInitialURL();
      respondSuccess({ url: null });

      const result = await promise;
      expect(result).toEqual({ url: null });
    });
  });

  describe('getAppState', () => {
    it('returns current app state', async () => {
      const promise = navigation.getAppState();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('navigation');
      expect(sent.action).toBe('getAppState');
      expect(sent.payload).toEqual({});

      respondSuccess({ state: 'active' });

      const result = await promise;
      expect(result).toEqual({ state: 'active' });
    });
  });

  describe('onDeepLink', () => {
    it('subscribes to deep link events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = navigation.onDeepLink((data) => {
        received.push(data);
      });

      simulateNativeEvent('navigation', 'deepLink', { url: 'myapp://product/42' });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ url: 'myapp://product/42' });

      unsubscribe();
      simulateNativeEvent('navigation', 'deepLink', { url: 'myapp://product/99' });

      expect(received).toHaveLength(1);
    });
  });

  describe('onAppStateChange', () => {
    it('subscribes to app state change events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = navigation.onAppStateChange((data) => {
        received.push(data);
      });

      simulateNativeEvent('navigation', 'appStateChange', { state: 'background' });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ state: 'background' });

      unsubscribe();
      simulateNativeEvent('navigation', 'appStateChange', { state: 'active' });

      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = navigation.push({ screen: 'Unknown' });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Navigation failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Navigation failed');
    });
  });
});
