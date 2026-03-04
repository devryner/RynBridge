import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { CryptoModule } from '../CryptoModule.js';

describe('CryptoModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let crypto: CryptoModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    crypto = new CryptoModule(bridge);
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

  describe('generateKeyPair', () => {
    it('sends correct module and action and returns public key', async () => {
      const promise = crypto.generateKeyPair();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('crypto');
      expect(sent.action).toBe('generateKeyPair');
      expect(sent.payload).toEqual({});

      respondSuccess({ publicKey: 'pk-abc123' });
      const result = await promise;
      expect(result.publicKey).toBe('pk-abc123');
    });
  });

  describe('performKeyExchange', () => {
    it('sends remote public key and returns session status', async () => {
      const promise = crypto.performKeyExchange({ remotePublicKey: 'remote-pk' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('performKeyExchange');
      expect(sent.payload).toEqual({ remotePublicKey: 'remote-pk' });

      respondSuccess({ sessionEstablished: true });
      const result = await promise;
      expect(result.sessionEstablished).toBe(true);
    });
  });

  describe('encrypt', () => {
    it('encrypts data and returns ciphertext', async () => {
      const promise = crypto.encrypt({ data: 'hello world', associatedData: 'ctx' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('encrypt');
      expect(sent.payload).toEqual({ data: 'hello world', associatedData: 'ctx' });

      respondSuccess({ ciphertext: 'enc-data', iv: 'iv-123', tag: 'tag-456' });
      const result = await promise;
      expect(result.ciphertext).toBe('enc-data');
      expect(result.iv).toBe('iv-123');
      expect(result.tag).toBe('tag-456');
    });
  });

  describe('decrypt', () => {
    it('decrypts ciphertext and returns plaintext', async () => {
      const promise = crypto.decrypt({ ciphertext: 'enc-data', iv: 'iv-123', tag: 'tag-456' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('decrypt');

      respondSuccess({ plaintext: 'hello world' });
      const result = await promise;
      expect(result.plaintext).toBe('hello world');
    });
  });

  describe('getStatus', () => {
    it('returns crypto status', async () => {
      const promise = crypto.getStatus();
      respondSuccess({ initialized: true, keyCreatedAt: '2026-01-01T00:00:00Z', algorithm: 'X25519+AES-GCM' });
      const result = await promise;
      expect(result.initialized).toBe(true);
      expect(result.keyCreatedAt).toBe('2026-01-01T00:00:00Z');
      expect(result.algorithm).toBe('X25519+AES-GCM');
    });

    it('returns uninitialized status', async () => {
      const promise = crypto.getStatus();
      respondSuccess({ initialized: false, keyCreatedAt: null, algorithm: 'X25519+AES-GCM' });
      const result = await promise;
      expect(result.initialized).toBe(false);
      expect(result.keyCreatedAt).toBeNull();
    });
  });

  describe('rotateKeys', () => {
    it('rotates keys and returns new public key', async () => {
      const promise = crypto.rotateKeys();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('rotateKeys');

      respondSuccess({ publicKey: 'new-pk-xyz' });
      const result = await promise;
      expect(result.publicKey).toBe('new-pk-xyz');
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = crypto.encrypt({ data: 'test' });
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Encryption failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Encryption failed');
    });
  });
});
