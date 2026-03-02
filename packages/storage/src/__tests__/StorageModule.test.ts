import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { StorageModule } from '../StorageModule.js';

describe('StorageModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let storage: StorageModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    storage = new StorageModule(bridge);
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
      const promise = storage.get('theme');

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('get');
      expect(sent.payload).toEqual({ key: 'theme' });

      respondSuccess({ value: 'dark' });

      const result = await promise;
      expect(result).toBe('dark');
    });

    it('returns null for missing key', async () => {
      const promise = storage.get('missing');
      respondSuccess({ value: null });

      const result = await promise;
      expect(result).toBeNull();
    });
  });

  describe('set', () => {
    it('sends correct module, action, key and value', async () => {
      const promise = storage.set('theme', 'dark');

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('set');
      expect(sent.payload).toEqual({ key: 'theme', value: 'dark' });

      respondSuccess();
      await promise;
    });
  });

  describe('remove', () => {
    it('sends correct module, action, and key', async () => {
      const promise = storage.remove('theme');

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('remove');
      expect(sent.payload).toEqual({ key: 'theme' });

      respondSuccess();
      await promise;
    });
  });

  describe('clear', () => {
    it('sends correct module and action with empty payload', async () => {
      const promise = storage.clear();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('clear');
      expect(sent.payload).toEqual({});

      respondSuccess();
      await promise;
    });
  });

  describe('keys', () => {
    it('returns array of keys', async () => {
      const promise = storage.keys();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('keys');

      respondSuccess({ keys: ['theme', 'lang', 'token'] });

      const result = await promise;
      expect(result).toEqual(['theme', 'lang', 'token']);
    });

    it('returns empty array when no keys', async () => {
      const promise = storage.keys();
      respondSuccess({ keys: [] });

      const result = await promise;
      expect(result).toEqual([]);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = storage.get('secret');

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Storage unavailable' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Storage unavailable');
    });
  });
});
