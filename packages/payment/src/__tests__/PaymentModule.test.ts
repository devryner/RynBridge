import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { PaymentModule } from '../PaymentModule.js';

describe('PaymentModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let payment: PaymentModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    payment = new PaymentModule(bridge);
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

  describe('getProducts', () => {
    it('sends product IDs and returns products', async () => {
      const promise = payment.getProducts({ productIds: ['p1', 'p2'] });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('payment');
      expect(sent.action).toBe('getProducts');
      expect(sent.payload).toEqual({ productIds: ['p1', 'p2'] });

      respondSuccess({
        products: [
          { id: 'p1', title: 'Item 1', description: 'Desc', price: '9.99', currency: 'USD' },
        ],
      });
      const result = await promise;
      expect(result.products).toHaveLength(1);
      expect(result.products[0].id).toBe('p1');
    });
  });

  describe('purchase', () => {
    it('sends purchase payload and returns result', async () => {
      const promise = payment.purchase({ productId: 'p1', quantity: 2 });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('payment');
      expect(sent.action).toBe('purchase');
      expect(sent.payload).toEqual({ productId: 'p1', quantity: 2 });

      respondSuccess({ transactionId: 'tx1', productId: 'p1', receipt: 'rcpt' });
      const result = await promise;
      expect(result.transactionId).toBe('tx1');
    });
  });

  describe('restorePurchases', () => {
    it('returns restored transactions', async () => {
      const promise = payment.restorePurchases();
      respondSuccess({
        transactions: [
          { transactionId: 'tx1', productId: 'p1', purchaseDate: '2026-01-01', receipt: 'r1' },
        ],
      });
      const result = await promise;
      expect(result.transactions).toHaveLength(1);
    });
  });

  describe('finishTransaction', () => {
    it('sends finish transaction request', async () => {
      const promise = payment.finishTransaction({ transactionId: 'tx1' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('finishTransaction');
      expect(sent.payload).toEqual({ transactionId: 'tx1' });
      respondSuccess();
      await promise;
    });
  });

  describe('onTransactionUpdate', () => {
    it('subscribes to transaction update events and returns unsubscribe', () => {
      const received: unknown[] = [];
      const unsub = payment.onTransactionUpdate((data) => received.push(data));

      simulateNativeEvent('payment', 'transactionUpdate', { transactionId: 'tx1', productId: 'p1', status: 'purchased' });
      expect(received).toHaveLength(1);
      expect((received[0] as any).status).toBe('purchased');

      unsub();
      simulateNativeEvent('payment', 'transactionUpdate', { transactionId: 'tx2', productId: 'p2', status: 'failed' });
      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = payment.purchase({ productId: 'p1' });
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Purchase failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Purchase failed');
    });
  });
});
