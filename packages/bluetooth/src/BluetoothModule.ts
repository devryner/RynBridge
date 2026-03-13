import { RynBridge } from '@rynbridge/core';
import type {
  StartScanPayload,
  StartScanResult,
  ConnectPayload,
  ConnectResult,
  DisconnectPayload,
  DisconnectResult,
  GetServicesPayload,
  GetServicesResult,
  ReadCharacteristicPayload,
  ReadCharacteristicResult,
  WriteCharacteristicPayload,
  WriteCharacteristicResult,
  DeviceFoundEvent,
  CharacteristicChangeEvent,
  PermissionResult,
  BluetoothState,
  StateChangeEvent,
} from './types.js';

const MODULE = 'bluetooth';

export class BluetoothModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async startScan(payload?: StartScanPayload): Promise<StartScanResult> {
    const result = await this.bridge.call(MODULE, 'startScan', (payload ?? {}) as Record<string, unknown>);
    return result as unknown as StartScanResult;
  }

  stopScan(): void {
    this.bridge.send(MODULE, 'stopScan', {});
  }

  onDeviceFound(listener: (data: DeviceFoundEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as DeviceFoundEvent);
    this.bridge.onEvent('bluetooth:deviceFound', wrapper);
    return () => this.bridge.offEvent('bluetooth:deviceFound', wrapper);
  }

  async connect(payload: ConnectPayload): Promise<ConnectResult> {
    const result = await this.bridge.call(MODULE, 'connect', payload as unknown as Record<string, unknown>);
    return result as unknown as ConnectResult;
  }

  async disconnect(payload: DisconnectPayload): Promise<DisconnectResult> {
    const result = await this.bridge.call(MODULE, 'disconnect', payload as unknown as Record<string, unknown>);
    return result as unknown as DisconnectResult;
  }

  async getServices(payload: GetServicesPayload): Promise<GetServicesResult> {
    const result = await this.bridge.call(MODULE, 'getServices', payload as unknown as Record<string, unknown>);
    return result as unknown as GetServicesResult;
  }

  async readCharacteristic(payload: ReadCharacteristicPayload): Promise<ReadCharacteristicResult> {
    const result = await this.bridge.call(MODULE, 'readCharacteristic', payload as unknown as Record<string, unknown>);
    return result as unknown as ReadCharacteristicResult;
  }

  async writeCharacteristic(payload: WriteCharacteristicPayload): Promise<WriteCharacteristicResult> {
    const result = await this.bridge.call(MODULE, 'writeCharacteristic', payload as unknown as Record<string, unknown>);
    return result as unknown as WriteCharacteristicResult;
  }

  onCharacteristicChange(listener: (data: CharacteristicChangeEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as CharacteristicChangeEvent);
    this.bridge.onEvent('bluetooth:characteristicChange', wrapper);
    return () => this.bridge.offEvent('bluetooth:characteristicChange', wrapper);
  }

  async requestPermission(): Promise<PermissionResult> {
    const result = await this.bridge.call(MODULE, 'requestPermission');
    return result as unknown as PermissionResult;
  }

  async getState(): Promise<BluetoothState> {
    const result = await this.bridge.call(MODULE, 'getState');
    return result as unknown as BluetoothState;
  }

  onStateChange(listener: (data: StateChangeEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as StateChangeEvent);
    this.bridge.onEvent('bluetooth:stateChange', wrapper);
    return () => this.bridge.offEvent('bluetooth:stateChange', wrapper);
  }
}
