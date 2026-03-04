import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { AuthModule } from '../AuthModule.js';

describe('AuthModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let auth: AuthModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    auth = new AuthModule(bridge);
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

  describe('login', () => {
    it('sends correct module, action and payload', async () => {
      const promise = auth.login({ provider: 'google', scopes: ['email', 'profile'] });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('auth');
      expect(sent.action).toBe('login');
      expect(sent.payload).toEqual({ provider: 'google', scopes: ['email', 'profile'] });

      respondSuccess({ token: 'abc123', refreshToken: null, expiresAt: '2026-12-31', user: null });
      const result = await promise;
      expect(result.token).toBe('abc123');
      expect(result.refreshToken).toBeNull();
    });
  });

  describe('logout', () => {
    it('sends correct module and action', async () => {
      const promise = auth.logout();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('auth');
      expect(sent.action).toBe('logout');
      respondSuccess();
      await promise;
    });
  });

  describe('getToken', () => {
    it('returns token result', async () => {
      const promise = auth.getToken();
      respondSuccess({ token: 'tok', expiresAt: '2026-12-31' });
      const result = await promise;
      expect(result.token).toBe('tok');
      expect(result.expiresAt).toBe('2026-12-31');
    });
  });

  describe('refreshToken', () => {
    it('returns refreshed login result', async () => {
      const promise = auth.refreshToken();
      respondSuccess({ token: 'new-tok', refreshToken: 'ref', expiresAt: '2027-01-01', user: { id: 'u1', email: 'a@b.com', name: 'A', profileImage: null } });
      const result = await promise;
      expect(result.token).toBe('new-tok');
      expect(result.user?.id).toBe('u1');
    });
  });

  describe('getUser', () => {
    it('returns user result', async () => {
      const promise = auth.getUser();
      respondSuccess({ user: { id: 'u1', email: null, name: 'Test', profileImage: null } });
      const result = await promise;
      expect(result.user?.name).toBe('Test');
    });
  });

  describe('onAuthStateChange', () => {
    it('subscribes to auth state events and returns unsubscribe', () => {
      const received: unknown[] = [];
      const unsub = auth.onAuthStateChange((data) => received.push(data));

      simulateNativeEvent('auth', 'authStateChange', { authenticated: true, user: { id: 'u1', email: null, name: null, profileImage: null } });
      expect(received).toHaveLength(1);
      expect((received[0] as any).authenticated).toBe(true);

      unsub();
      simulateNativeEvent('auth', 'authStateChange', { authenticated: false, user: null });
      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = auth.login({ provider: 'google' });
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Auth failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Auth failed');
    });
  });
});
