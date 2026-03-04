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

export interface CapturePhotoPayload {
  quality?: number;
  camera?: 'front' | 'back';
}

export interface CapturePhotoResult {
  imageBase64: string;
  width: number;
  height: number;
}

export interface LocationInfo {
  latitude: number;
  longitude: number;
  accuracy: number;
}

export interface AuthenticatePayload {
  reason: string;
}

export interface AuthenticateResult {
  success: boolean;
}

export interface KeyboardInfo {
  height: number;
  visible: boolean;
}
