import type { RynBridge } from '@rynbridge/core';
import type {
  RequestPermissionPayload,
  PermissionResult,
  PermissionStatus,
  QueryDataPayload,
  QueryDataResult,
  WriteDataPayload,
  WriteDataResult,
  GetStepsPayload,
  GetStepsResult,
  IsAvailableResult,
  DataChangeEvent,
} from './types.js';

const MODULE = 'health';

export class HealthModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async requestPermission(payload: RequestPermissionPayload): Promise<PermissionResult> {
    const result = await this.bridge.call(MODULE, 'requestPermission', payload as unknown as Record<string, unknown>);
    return result as unknown as PermissionResult;
  }

  async getPermissionStatus(): Promise<PermissionStatus> {
    const result = await this.bridge.call(MODULE, 'getPermissionStatus');
    return result as unknown as PermissionStatus;
  }

  async queryData(payload: QueryDataPayload): Promise<QueryDataResult> {
    const result = await this.bridge.call(MODULE, 'queryData', payload as unknown as Record<string, unknown>);
    return result as unknown as QueryDataResult;
  }

  async writeData(payload: WriteDataPayload): Promise<WriteDataResult> {
    const result = await this.bridge.call(MODULE, 'writeData', payload as unknown as Record<string, unknown>);
    return result as unknown as WriteDataResult;
  }

  async getSteps(payload: GetStepsPayload): Promise<GetStepsResult> {
    const result = await this.bridge.call(MODULE, 'getSteps', payload as unknown as Record<string, unknown>);
    return result as unknown as GetStepsResult;
  }

  async isAvailable(): Promise<IsAvailableResult> {
    const result = await this.bridge.call(MODULE, 'isAvailable');
    return result as unknown as IsAvailableResult;
  }

  onDataChange(listener: (data: DataChangeEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as DataChangeEvent);
    this.bridge.onEvent('health:dataChange', wrapper);
    return () => this.bridge.offEvent('health:dataChange', wrapper);
  }
}
