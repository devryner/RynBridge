import { RynBridge } from '@rynbridge/core';
import type {
  FcmToken,
  FcmAutoInit,
  FcmTopicSubscription,
  FcmTokenRefresh,
} from './types.js';

const MODULE = 'push-fcm';

export class PushFcmModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async getToken(): Promise<FcmToken> {
    const result = await this.bridge.call(MODULE, 'getToken');
    return result as unknown as FcmToken;
  }

  async deleteToken(): Promise<void> {
    await this.bridge.call(MODULE, 'deleteToken');
  }

  async subscribeToTopic(topic: string): Promise<void> {
    await this.bridge.call(MODULE, 'subscribeToTopic', { topic });
  }

  async unsubscribeFromTopic(topic: string): Promise<void> {
    await this.bridge.call(MODULE, 'unsubscribeFromTopic', { topic });
  }

  async getAutoInitEnabled(): Promise<FcmAutoInit> {
    const result = await this.bridge.call(MODULE, 'getAutoInitEnabled');
    return result as unknown as FcmAutoInit;
  }

  async setAutoInitEnabled(enabled: boolean): Promise<void> {
    await this.bridge.call(MODULE, 'setAutoInitEnabled', { enabled });
  }

  onTokenRefresh(listener: (data: FcmTokenRefresh) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as FcmTokenRefresh);
    this.bridge.onEvent('push-fcm:tokenRefresh', wrapper);
    return () => this.bridge.offEvent('push-fcm:tokenRefresh', wrapper);
  }
}
