export interface DeviceInfo {
  platform: string;
  osVersion: string;
  model: string;
  appVersion: string;
}

export interface BatteryInfo {
  level: number;
  isCharging: boolean;
}

export interface ScreenInfo {
  width: number;
  height: number;
  scale: number;
  orientation: string;
}

export interface VibratePayload {
  pattern?: number[];
}
