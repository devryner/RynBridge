import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { TranslationModule } from '../TranslationModule.js';

describe('TranslationModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let translation: TranslationModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    translation = new TranslationModule(bridge);
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

  describe('translate', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = translation.translate({ text: 'Hello', source: 'en', target: 'ko' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('translation');
      expect(sent.action).toBe('translate');
      expect(sent.payload).toEqual({ text: 'Hello', source: 'en', target: 'ko' });

      respondSuccess({ text: '안녕하세요' });

      const result = await promise;
      expect(result).toEqual({ text: '안녕하세요' });
    });
  });

  describe('translateBatch', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = translation.translateBatch({ texts: ['Hello', 'World'], source: 'en', target: 'ko' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('translation');
      expect(sent.action).toBe('translateBatch');
      expect(sent.payload).toEqual({ texts: ['Hello', 'World'], source: 'en', target: 'ko' });

      respondSuccess({ results: ['안녕하세요', '세계'] });

      const result = await promise;
      expect(result).toEqual({ results: ['안녕하세요', '세계'] });
    });
  });

  describe('detectLanguage', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = translation.detectLanguage({ text: '안녕하세요' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('translation');
      expect(sent.action).toBe('detectLanguage');
      expect(sent.payload).toEqual({ text: '안녕하세요' });

      respondSuccess({ language: 'ko', confidence: 0.95 });

      const result = await promise;
      expect(result).toEqual({ language: 'ko', confidence: 0.95 });
    });
  });

  describe('getSupportedLanguages', () => {
    it('sends correct module and action', async () => {
      const promise = translation.getSupportedLanguages();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('translation');
      expect(sent.action).toBe('getSupportedLanguages');
      expect(sent.payload).toEqual({});

      respondSuccess({ languages: ['en', 'ko', 'ja', 'zh'] });

      const result = await promise;
      expect(result).toEqual({ languages: ['en', 'ko', 'ja', 'zh'] });
    });
  });

  describe('downloadModel', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = translation.downloadModel({ language: 'ko' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('translation');
      expect(sent.action).toBe('downloadModel');
      expect(sent.payload).toEqual({ language: 'ko' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('deleteModel', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = translation.deleteModel({ language: 'ko' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('translation');
      expect(sent.action).toBe('deleteModel');
      expect(sent.payload).toEqual({ language: 'ko' });

      respondSuccess({ success: true });

      const result = await promise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('getDownloadedModels', () => {
    it('sends correct module and action', async () => {
      const promise = translation.getDownloadedModels();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('translation');
      expect(sent.action).toBe('getDownloadedModels');
      expect(sent.payload).toEqual({});

      respondSuccess({ models: ['en', 'ko'] });

      const result = await promise;
      expect(result).toEqual({ models: ['en', 'ko'] });
    });
  });

  describe('onDownloadProgress', () => {
    it('subscribes to download progress events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = translation.onDownloadProgress((data) => {
        received.push(data);
      });

      simulateNativeEvent('translation', 'downloadProgress', { language: 'ko', progress: 0.5 });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ language: 'ko', progress: 0.5 });

      unsubscribe();
      simulateNativeEvent('translation', 'downloadProgress', { language: 'ko', progress: 0.75 });

      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = translation.translate({ text: 'Hello', source: 'en', target: 'ko' });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Translation service unavailable' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Translation service unavailable');
    });
  });
});
