import { RynBridge } from '@rynbridge/core';
import type {
  KeyPairResult,
  KeyExchangePayload,
  KeyExchangeResult,
  EncryptPayload,
  EncryptResult,
  DecryptPayload,
  DecryptResult,
  CryptoStatus,
} from './types.js';

const MODULE = 'crypto';

export class CryptoModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async generateKeyPair(): Promise<KeyPairResult> {
    const result = await this.bridge.call(MODULE, 'generateKeyPair');
    return result as unknown as KeyPairResult;
  }

  async performKeyExchange(payload: KeyExchangePayload): Promise<KeyExchangeResult> {
    const result = await this.bridge.call(MODULE, 'performKeyExchange', payload as unknown as Record<string, unknown>);
    return result as unknown as KeyExchangeResult;
  }

  async encrypt(payload: EncryptPayload): Promise<EncryptResult> {
    const result = await this.bridge.call(MODULE, 'encrypt', payload as unknown as Record<string, unknown>);
    return result as unknown as EncryptResult;
  }

  async decrypt(payload: DecryptPayload): Promise<DecryptResult> {
    const result = await this.bridge.call(MODULE, 'decrypt', payload as unknown as Record<string, unknown>);
    return result as unknown as DecryptResult;
  }

  async getStatus(): Promise<CryptoStatus> {
    const result = await this.bridge.call(MODULE, 'getStatus');
    return result as unknown as CryptoStatus;
  }

  async rotateKeys(): Promise<KeyPairResult> {
    const result = await this.bridge.call(MODULE, 'rotateKeys');
    return result as unknown as KeyPairResult;
  }
}
