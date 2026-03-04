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

  describe('readFile', () => {
    it('sends path and returns content', async () => {
      const promise = storage.readFile({ path: '/docs/readme.txt' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('readFile');
      expect(sent.payload).toEqual({ path: '/docs/readme.txt' });

      respondSuccess({ content: 'Hello World' });

      const result = await promise;
      expect(result).toBe('Hello World');
    });

    it('sends encoding option', async () => {
      const promise = storage.readFile({ path: '/images/photo.png', encoding: 'base64' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ path: '/images/photo.png', encoding: 'base64' });

      respondSuccess({ content: 'iVBORw0KGgo=' });

      const result = await promise;
      expect(result).toBe('iVBORw0KGgo=');
    });
  });

  describe('writeFile', () => {
    it('sends path and content, returns success', async () => {
      const promise = storage.writeFile({ path: '/docs/test.txt', content: 'test data' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('writeFile');
      expect(sent.payload).toEqual({ path: '/docs/test.txt', content: 'test data' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toBe(true);
    });

    it('sends encoding option', async () => {
      const promise = storage.writeFile({ path: '/bin/data', content: 'AQID', encoding: 'base64' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ path: '/bin/data', content: 'AQID', encoding: 'base64' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toBe(true);
    });
  });

  describe('deleteFile', () => {
    it('sends path and returns success', async () => {
      const promise = storage.deleteFile({ path: '/docs/old.txt' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('deleteFile');
      expect(sent.payload).toEqual({ path: '/docs/old.txt' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toBe(true);
    });
  });

  describe('listDir', () => {
    it('sends path and returns file list', async () => {
      const promise = storage.listDir({ path: '/docs' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('listDir');
      expect(sent.payload).toEqual({ path: '/docs' });

      respondSuccess({ files: ['readme.txt', 'notes.md', 'images'] });

      const result = await promise;
      expect(result).toEqual(['readme.txt', 'notes.md', 'images']);
    });

    it('returns empty array for empty directory', async () => {
      const promise = storage.listDir({ path: '/empty' });
      respondSuccess({ files: [] });

      const result = await promise;
      expect(result).toEqual([]);
    });
  });

  describe('getFileInfo', () => {
    it('returns file info', async () => {
      const promise = storage.getFileInfo({ path: '/docs/readme.txt' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('storage');
      expect(sent.action).toBe('getFileInfo');
      expect(sent.payload).toEqual({ path: '/docs/readme.txt' });

      respondSuccess({ size: 1024, modifiedAt: '2024-01-15T10:30:00Z', isDirectory: false });

      const result = await promise;
      expect(result).toEqual({ size: 1024, modifiedAt: '2024-01-15T10:30:00Z', isDirectory: false });
    });

    it('returns directory info', async () => {
      const promise = storage.getFileInfo({ path: '/docs' });
      respondSuccess({ size: 0, modifiedAt: '2024-01-15T10:30:00Z', isDirectory: true });

      const result = await promise;
      expect(result).toEqual({ size: 0, modifiedAt: '2024-01-15T10:30:00Z', isDirectory: true });
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
