import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { SecureStorageModule } from '../SecureStorageModule.js';

describe('SecureStorageModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let secureStorage: SecureStorageModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    secureStorage = new SecureStorageModule(bridge);
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

  describe('get', () => {
    it('sends correct module, action, and key', async () => {
      const promise = secureStorage.get('auth_token');

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('secure-storage');
      expect(sent.action).toBe('get');
      expect(sent.payload).toEqual({ key: 'auth_token' });

      respondSuccess({ value: 'abc123' });

      const result = await promise;
      expect(result).toBe('abc123');
    });

    it('returns null for missing key', async () => {
      const promise = secureStorage.get('missing');
      respondSuccess({ value: null });

      const result = await promise;
      expect(result).toBeNull();
    });
  });

  describe('set', () => {
    it('sends correct module, action, key and value', async () => {
      const promise = secureStorage.set('auth_token', 'xyz789');

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('secure-storage');
      expect(sent.action).toBe('set');
      expect(sent.payload).toEqual({ key: 'auth_token', value: 'xyz789' });

      respondSuccess();
      await promise;
    });
  });

  describe('remove', () => {
    it('sends correct module, action, and key', async () => {
      const promise = secureStorage.remove('auth_token');

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('secure-storage');
      expect(sent.action).toBe('remove');
      expect(sent.payload).toEqual({ key: 'auth_token' });

      respondSuccess();
      await promise;
    });
  });

  describe('has', () => {
    it('returns true when key exists', async () => {
      const promise = secureStorage.has('auth_token');

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('secure-storage');
      expect(sent.action).toBe('has');
      expect(sent.payload).toEqual({ key: 'auth_token' });

      respondSuccess({ exists: true });

      const result = await promise;
      expect(result).toBe(true);
    });

    it('returns false when key does not exist', async () => {
      const promise = secureStorage.has('missing');
      respondSuccess({ exists: false });

      const result = await promise;
      expect(result).toBe(false);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = secureStorage.get('secret');

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Keychain access denied' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Keychain access denied');
    });
  });
});
