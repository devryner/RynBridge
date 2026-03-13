import { RynBridge } from '@rynbridge/core';
import type {
  DeviceInfo,
  BatteryInfo,
  ScreenInfo,
  VibratePayload,
  CapturePhotoPayload,
  CapturePhotoResult,
  LocationInfo,
  AuthenticatePayload,
  AuthenticateResult,
} from './types.js';

const MODULE = 'device';

export class DeviceModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
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

  async capturePhoto(payload?: CapturePhotoPayload): Promise<CapturePhotoResult> {
    const result = await this.bridge.call(MODULE, 'capturePhoto', (payload ?? {}) as Record<string, unknown>);
    return result as unknown as CapturePhotoResult;
  }

  async getLocation(): Promise<LocationInfo> {
    const result = await this.bridge.call(MODULE, 'getLocation');
    return result as unknown as LocationInfo;
  }

  async authenticate(payload: AuthenticatePayload): Promise<AuthenticateResult> {
    const result = await this.bridge.call(MODULE, 'authenticate', payload as unknown as Record<string, unknown>);
    return result as unknown as AuthenticateResult;
  }

  onLocationChange(listener: (data: LocationInfo) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as LocationInfo);
    this.bridge.onEvent('device:locationChange', wrapper);
    return () => this.bridge.offEvent('device:locationChange', wrapper);
  }

  onBatteryChange(listener: (data: BatteryInfo) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as BatteryInfo);
    this.bridge.onEvent('device:batteryChange', wrapper);
    return () => this.bridge.offEvent('device:batteryChange', wrapper);
  }
}
