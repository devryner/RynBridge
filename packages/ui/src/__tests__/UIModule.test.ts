import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { UIModule } from '../UIModule.js';

describe('UIModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let ui: UIModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    ui = new UIModule(bridge);
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

  describe('showAlert', () => {
    it('sends correct module, action, and payload', async () => {
      const promise = ui.showAlert({ title: 'Warning', message: 'Are you sure?' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('showAlert');
      expect(sent.payload).toEqual({ title: 'Warning', message: 'Are you sure?' });

      respondSuccess();
      await promise;
    });

    it('sends optional buttonText', async () => {
      const promise = ui.showAlert({ title: 'Info', message: 'Done', buttonText: 'OK' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ title: 'Info', message: 'Done', buttonText: 'OK' });

      respondSuccess();
      await promise;
    });
  });

  describe('showConfirm', () => {
    it('returns true when confirmed', async () => {
      const promise = ui.showConfirm({ title: 'Delete', message: 'Delete this item?' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('showConfirm');
      expect(sent.payload).toEqual({ title: 'Delete', message: 'Delete this item?' });

      respondSuccess({ confirmed: true });

      const result = await promise;
      expect(result).toBe(true);
    });

    it('returns false when cancelled', async () => {
      const promise = ui.showConfirm({ title: 'Delete', message: 'Delete?' });
      respondSuccess({ confirmed: false });

      const result = await promise;
      expect(result).toBe(false);
    });
  });

  describe('showToast', () => {
    it('sends fire-and-forget with message', () => {
      ui.showToast({ message: 'Saved!' });

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('showToast');
      expect(sent.payload).toEqual({ message: 'Saved!' });
    });

    it('sends optional duration', () => {
      ui.showToast({ message: 'Loading...', duration: 3000 });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ message: 'Loading...', duration: 3000 });
    });
  });

  describe('showActionSheet', () => {
    it('returns selected index', async () => {
      const promise = ui.showActionSheet({
        title: 'Choose action',
        options: ['Edit', 'Delete', 'Cancel'],
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('showActionSheet');
      expect(sent.payload).toEqual({
        title: 'Choose action',
        options: ['Edit', 'Delete', 'Cancel'],
      });

      respondSuccess({ selectedIndex: 1 });

      const result = await promise;
      expect(result).toBe(1);
    });

    it('works without title', async () => {
      const promise = ui.showActionSheet({ options: ['A', 'B'] });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ options: ['A', 'B'] });

      respondSuccess({ selectedIndex: 0 });

      const result = await promise;
      expect(result).toBe(0);
    });
  });

  describe('setStatusBar', () => {
    it('sends correct payload with style', async () => {
      const promise = ui.setStatusBar({ style: 'light' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('setStatusBar');
      expect(sent.payload).toEqual({ style: 'light' });

      respondSuccess();
      await promise;
    });

    it('sends correct payload with hidden', async () => {
      const promise = ui.setStatusBar({ hidden: true });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ hidden: true });

      respondSuccess();
      await promise;
    });
  });

  describe('showKeyboard', () => {
    it('sends fire-and-forget', () => {
      ui.showKeyboard();

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('showKeyboard');
      expect(sent.payload).toEqual({});
    });
  });

  describe('hideKeyboard', () => {
    it('sends fire-and-forget', () => {
      ui.hideKeyboard();

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('hideKeyboard');
      expect(sent.payload).toEqual({});
    });
  });

  describe('getKeyboardHeight', () => {
    it('returns keyboard height and visibility', async () => {
      const promise = ui.getKeyboardHeight();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('ui');
      expect(sent.action).toBe('getKeyboardHeight');
      expect(sent.payload).toEqual({});

      respondSuccess({ height: 336, visible: true });

      const result = await promise;
      expect(result).toEqual({ height: 336, visible: true });
    });

    it('returns zero height when keyboard is hidden', async () => {
      const promise = ui.getKeyboardHeight();
      respondSuccess({ height: 0, visible: false });

      const result = await promise;
      expect(result).toEqual({ height: 0, visible: false });
    });
  });

  describe('onKeyboardChange', () => {
    it('subscribes to keyboard events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = ui.onKeyboardChange((data) => {
        received.push(data);
      });

      simulateNativeEvent('ui', 'keyboardChange', { height: 336, visible: true });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ height: 336, visible: true });

      unsubscribe();
      simulateNativeEvent('ui', 'keyboardChange', { height: 0, visible: false });

      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = ui.showAlert({ title: 'Test', message: 'Test' });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'UI not available' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('UI not available');
    });
  });
});
