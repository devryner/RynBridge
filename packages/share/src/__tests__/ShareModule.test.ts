import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { ShareModule } from '../ShareModule.js';

describe('ShareModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let share: ShareModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    share = new ShareModule(bridge);
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

  describe('share', () => {
    it('sends share request and returns result', async () => {
      const promise = share.share({ text: 'Hello', url: 'https://example.com', title: 'Test' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('share');
      expect(sent.action).toBe('share');
      expect(sent.payload).toEqual({ text: 'Hello', url: 'https://example.com', title: 'Test' });

      respondSuccess({ success: true });
      const result = await promise;
      expect(result.success).toBe(true);
    });
  });

  describe('shareFile', () => {
    it('sends share file request', async () => {
      const promise = share.shareFile({ filePath: '/tmp/file.pdf', mimeType: 'application/pdf' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('shareFile');
      respondSuccess({ success: true });
      const result = await promise;
      expect(result.success).toBe(true);
    });
  });

  describe('copyToClipboard', () => {
    it('sends copy to clipboard command', () => {
      share.copyToClipboard({ text: 'copied text' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('copyToClipboard');
      expect(sent.payload).toEqual({ text: 'copied text' });
    });
  });

  describe('readClipboard', () => {
    it('reads clipboard text', async () => {
      const promise = share.readClipboard();
      respondSuccess({ text: 'clipboard content' });
      const result = await promise;
      expect(result.text).toBe('clipboard content');
    });
  });

  describe('canShare', () => {
    it('checks share capability', async () => {
      const promise = share.canShare();
      respondSuccess({ canShare: true });
      const result = await promise;
      expect(result.canShare).toBe(true);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = share.share({ text: 'test' });
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Share failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Share failed');
    });
  });
});
