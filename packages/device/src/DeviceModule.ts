import type { RynBridge } from '@rynbridge/core';
import type { DeviceInfo, BatteryInfo, ScreenInfo, VibratePayload } from './types.js';

const MODULE = 'device';

export class DeviceModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async getInfo(): Promise<DeviceInfo> {
    const result = await this.bridge.call(MODULE, 'getInfo');
    return result as unknown as DeviceInfo;
  }

  async getBattery(): Promise<BatteryInfo> {
    const result = await this.bridge.call(MODULE, 'getBattery');
    return result as unknown as BatteryInfo;
  }

  async getScreen(): Promise<ScreenInfo> {
    const result = await this.bridge.call(MODULE, 'getScreen');
    return result as unknown as ScreenInfo;
  }

  vibrate(payload?: VibratePayload): void {
    this.bridge.send(MODULE, 'vibrate', (payload ?? {}) as Record<string, unknown>);
  }
}
