import type { RynBridge } from '@rynbridge/core';
import type {
  PushRegistration,
  PushToken,
  PushPermission,
  PushPermissionStatus,
  PushNotification,
  PushTokenRefresh,
} from './types.js';

const MODULE = 'push';

export class PushModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async register(): Promise<PushRegistration> {
    const result = await this.bridge.call(MODULE, 'register');
    return result as unknown as PushRegistration;
  }

  async unregister(): Promise<void> {
    await this.bridge.call(MODULE, 'unregister');
  }

  async getToken(): Promise<PushToken> {
    const result = await this.bridge.call(MODULE, 'getToken');
    return result as unknown as PushToken;
  }

  async requestPermission(): Promise<PushPermission> {
    const result = await this.bridge.call(MODULE, 'requestPermission');
    return result as unknown as PushPermission;
  }

  async getPermissionStatus(): Promise<PushPermissionStatus> {
    const result = await this.bridge.call(MODULE, 'getPermissionStatus');
    return result as unknown as PushPermissionStatus;
  }

  onNotification(listener: (data: PushNotification) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as PushNotification);
    this.bridge.onEvent('push:notification', wrapper);
    return () => this.bridge.offEvent('push:notification', wrapper);
  }

  onTokenRefresh(listener: (data: PushTokenRefresh) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as PushTokenRefresh);
    this.bridge.onEvent('push:tokenRefresh', wrapper);
    return () => this.bridge.offEvent('push:tokenRefresh', wrapper);
  }
}
