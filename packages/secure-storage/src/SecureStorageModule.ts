import type { RynBridge } from '@rynbridge/core';
import type {
  SecureStorageGetResponse,
  SecureStorageHasResponse,
} from './types.js';

const MODULE = 'secure-storage';

export class SecureStorageModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async get(key: string): Promise<string | null> {
    const result = await this.bridge.call(MODULE, 'get', { key });
    return (result as unknown as SecureStorageGetResponse).value;
  }

  async set(key: string, value: string): Promise<void> {
    await this.bridge.call(MODULE, 'set', { key, value });
  }

  async remove(key: string): Promise<void> {
    await this.bridge.call(MODULE, 'remove', { key });
  }

  async has(key: string): Promise<boolean> {
    const result = await this.bridge.call(MODULE, 'has', { key });
    return (result as unknown as SecureStorageHasResponse).exists;
  }
}
