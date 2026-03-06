export interface StartScanPayload {
  serviceUUIDs?: string[];
}

export interface StartScanResult {
  success: boolean;
}

export interface StopScanPayload {}

export interface DeviceFoundEvent {
  deviceId: string;
  name: string | null;
  rssi: number;
  serviceUUIDs: string[];
}

export interface ConnectPayload {
  deviceId: string;
}

export interface ConnectResult {
  success: boolean;
}

export interface DisconnectPayload {
  deviceId: string;
}

export interface DisconnectResult {
  success: boolean;
}

export interface GetServicesPayload {
  deviceId: string;
}

export interface BluetoothService {
  uuid: string;
  characteristics: BluetoothCharacteristic[];
}

export interface BluetoothCharacteristic {
  uuid: string;
  properties: string[];
}

export interface GetServicesResult {
  services: BluetoothService[];
}

export interface ReadCharacteristicPayload {
  deviceId: string;
  serviceUUID: string;
  characteristicUUID: string;
}

export interface ReadCharacteristicResult {
  value: string;
}

export interface WriteCharacteristicPayload {
  deviceId: string;
  serviceUUID: string;
  characteristicUUID: string;
  value: string;
}

export interface WriteCharacteristicResult {
  success: boolean;
}

export interface CharacteristicChangeEvent {
  deviceId: string;
  serviceUUID: string;
  characteristicUUID: string;
  value: string;
}

export interface PermissionResult {
  granted: boolean;
}

export interface BluetoothState {
  state: 'poweredOn' | 'poweredOff' | 'unauthorized' | 'unsupported' | 'unknown';
}

export interface StateChangeEvent {
  state: 'poweredOn' | 'poweredOff' | 'unauthorized' | 'unsupported' | 'unknown';
}
