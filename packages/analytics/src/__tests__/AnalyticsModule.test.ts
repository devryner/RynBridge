import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { AnalyticsModule } from '../AnalyticsModule.js';

describe('AnalyticsModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let analytics: AnalyticsModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    analytics = new AnalyticsModule(bridge);
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

  describe('logEvent', () => {
    it('sends fire-and-forget with name only', () => {
      analytics.logEvent({ name: 'page_view' });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('logEvent');
      expect(sent.payload).toEqual({ name: 'page_view' });
    });

    it('sends fire-and-forget with name and params', () => {
      analytics.logEvent({ name: 'purchase', params: { amount: 100, currency: 'USD' } });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('logEvent');
      expect(sent.payload).toEqual({ name: 'purchase', params: { amount: 100, currency: 'USD' } });
    });
  });

  describe('setUserProperty', () => {
    it('sends fire-and-forget with key and value', () => {
      analytics.setUserProperty({ key: 'plan', value: 'premium' });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('setUserProperty');
      expect(sent.payload).toEqual({ key: 'plan', value: 'premium' });
    });
  });

  describe('setUserId', () => {
    it('sends fire-and-forget with userId', () => {
      analytics.setUserId({ userId: 'user-123' });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('setUserId');
      expect(sent.payload).toEqual({ userId: 'user-123' });
    });
  });

  describe('setScreen', () => {
    it('sends fire-and-forget with screen name', () => {
      analytics.setScreen({ name: 'HomeScreen' });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('setScreen');
      expect(sent.payload).toEqual({ name: 'HomeScreen' });
    });
  });

  describe('resetUser', () => {
    it('sends fire-and-forget with empty payload', () => {
      analytics.resetUser();

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('resetUser');
      expect(sent.payload).toEqual({});
    });
  });

  describe('setEnabled', () => {
    it('sends request and returns enabled state', async () => {
      const promise = analytics.setEnabled({ enabled: false });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('setEnabled');
      expect(sent.payload).toEqual({ enabled: false });

      respondSuccess({ enabled: false });

      const result = await promise;
      expect(result).toEqual({ enabled: false });
    });

    it('can enable tracking', async () => {
      const promise = analytics.setEnabled({ enabled: true });
      respondSuccess({ enabled: true });

      const result = await promise;
      expect(result).toEqual({ enabled: true });
    });
  });

  describe('isEnabled', () => {
    it('sends request and returns current enabled state', async () => {
      const promise = analytics.isEnabled();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('analytics');
      expect(sent.action).toBe('isEnabled');
      expect(sent.payload).toEqual({});

      respondSuccess({ enabled: true });

      const result = await promise;
      expect(result).toEqual({ enabled: true });
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors on setEnabled', async () => {
      const promise = analytics.setEnabled({ enabled: false });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Analytics provider not configured' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Analytics provider not configured');
    });

    it('propagates bridge errors on isEnabled', async () => {
      const promise = analytics.isEnabled();

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Analytics provider not configured' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Analytics provider not configured');
    });
  });
});
