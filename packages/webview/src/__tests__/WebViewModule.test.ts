import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { WebViewModule } from '../WebViewModule.js';

describe('WebViewModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let webview: WebViewModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    webview = new WebViewModule(bridge);
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

  describe('open', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = webview.open({ url: 'https://example.com', title: 'Test', style: 'modal' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('webview');
      expect(sent.action).toBe('open');
      expect(sent.payload).toEqual({ url: 'https://example.com', title: 'Test', style: 'modal' });

      respondSuccess({ webviewId: 'wv-123' });

      const result = await promise;
      expect(result).toEqual({ webviewId: 'wv-123' });
    });

    it('sends with allowedOrigins', async () => {
      const promise = webview.open({
        url: 'https://example.com',
        allowedOrigins: ['https://example.com', 'https://api.example.com'],
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({
        url: 'https://example.com',
        allowedOrigins: ['https://example.com', 'https://api.example.com'],
      });

      respondSuccess({ webviewId: 'wv-456' });

      const result = await promise;
      expect(result).toEqual({ webviewId: 'wv-456' });
    });
  });

  describe('close', () => {
    it('sends correct module and action', async () => {
      const promise = webview.close({ webviewId: 'wv-123' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('webview');
      expect(sent.action).toBe('close');
      expect(sent.payload).toEqual({ webviewId: 'wv-123' });

      respondSuccess();

      await promise;
    });
  });

  describe('sendMessage', () => {
    it('sends message to target WebView', async () => {
      const promise = webview.sendMessage({
        targetId: 'wv-456',
        data: { greeting: 'hello' },
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('webview');
      expect(sent.action).toBe('sendMessage');
      expect(sent.payload).toEqual({ targetId: 'wv-456', data: { greeting: 'hello' } });

      respondSuccess();

      await promise;
    });

    it('sends message to parent using reserved keyword', async () => {
      const promise = webview.sendMessage({
        targetId: 'parent',
        data: { result: 'done' },
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ targetId: 'parent', data: { result: 'done' } });

      respondSuccess();

      await promise;
    });
  });

  describe('postEvent', () => {
    it('sends fire-and-forget event', () => {
      webview.postEvent({ targetId: 'wv-789', event: 'refresh', data: { force: true } });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('webview');
      expect(sent.action).toBe('postEvent');
      expect(sent.payload).toEqual({ targetId: 'wv-789', event: 'refresh', data: { force: true } });
    });

    it('sends fire-and-forget event without data', () => {
      webview.postEvent({ targetId: 'parent', event: 'ping' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ targetId: 'parent', event: 'ping' });
    });
  });

  describe('onMessage', () => {
    it('subscribes to message events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = webview.onMessage((data) => {
        received.push(data);
      });

      simulateNativeEvent('webview', 'message', { sourceId: 'wv-123', data: { greeting: 'hi' } });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ sourceId: 'wv-123', data: { greeting: 'hi' } });

      unsubscribe();
      simulateNativeEvent('webview', 'message', { sourceId: 'wv-123', data: { greeting: 'again' } });

      expect(received).toHaveLength(1);
    });
  });

  describe('onClose', () => {
    it('subscribes to close events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = webview.onClose((data) => {
        received.push(data);
      });

      simulateNativeEvent('webview', 'close', { webviewId: 'wv-123', result: { status: 'ok' } });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ webviewId: 'wv-123', result: { status: 'ok' } });

      unsubscribe();
      simulateNativeEvent('webview', 'close', { webviewId: 'wv-456' });

      expect(received).toHaveLength(1);
    });

    it('receives close event without result', () => {
      const received: unknown[] = [];
      webview.onClose((data) => {
        received.push(data);
      });

      simulateNativeEvent('webview', 'close', { webviewId: 'wv-123' });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ webviewId: 'wv-123' });
    });
  });

  describe('getWebViews', () => {
    it('returns list of open WebViews', async () => {
      const promise = webview.getWebViews();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('webview');
      expect(sent.action).toBe('getWebViews');
      expect(sent.payload).toEqual({});

      respondSuccess({
        webviews: [
          { webviewId: 'wv-1', url: 'https://a.com', title: 'A' },
          { webviewId: 'wv-2', url: 'https://b.com' },
        ],
      });

      const result = await promise;
      expect(result).toEqual({
        webviews: [
          { webviewId: 'wv-1', url: 'https://a.com', title: 'A' },
          { webviewId: 'wv-2', url: 'https://b.com' },
        ],
      });
    });
  });

  describe('setResult', () => {
    it('sends fire-and-forget result data', () => {
      webview.setResult({ data: { selectedItem: 'item-1', quantity: 3 } });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('webview');
      expect(sent.action).toBe('setResult');
      expect(sent.payload).toEqual({ data: { selectedItem: 'item-1', quantity: 3 } });
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = webview.open({ url: 'https://example.com' });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'WebView creation failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('WebView creation failed');
    });
  });
});
