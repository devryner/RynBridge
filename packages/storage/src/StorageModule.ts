import type { RynBridge } from '@rynbridge/core';
import type {
  StorageGetResponse,
  StorageKeysResponse,
} from './types.js';

const MODULE = 'storage';

export class StorageModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async get(key: string): Promise<string | null> {
    const result = await this.bridge.call(MODULE, 'get', { key });
    return (result as unknown as StorageGetResponse).value;
  }

  async set(key: string, value: string): Promise<void> {
    await this.bridge.call(MODULE, 'set', { key, value });
  }

  async remove(key: string): Promise<void> {
    await this.bridge.call(MODULE, 'remove', { key });
  }

  async clear(): Promise<void> {
    await this.bridge.call(MODULE, 'clear');
  }

  async keys(): Promise<string[]> {
    const result = await this.bridge.call(MODULE, 'keys');
    return (result as unknown as StorageKeysResponse).keys;
  }
}
