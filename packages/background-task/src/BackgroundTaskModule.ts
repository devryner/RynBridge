import { RynBridge } from '@rynbridge/core';
import type {
  ScheduleTaskPayload,
  ScheduleTaskResult,
  CancelTaskPayload,
  CancelTaskResult,
  CancelAllTasksResult,
  GetScheduledTasksResult,
  TaskExecuteEvent,
  CompleteTaskPayload,
  PermissionResult,
} from './types.js';

const MODULE = 'backgroundTask';

export class BackgroundTaskModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async scheduleTask(payload: ScheduleTaskPayload): Promise<ScheduleTaskResult> {
    const result = await this.bridge.call(MODULE, 'scheduleTask', payload as unknown as Record<string, unknown>);
    return result as unknown as ScheduleTaskResult;
  }

  async cancelTask(payload: CancelTaskPayload): Promise<CancelTaskResult> {
    const result = await this.bridge.call(MODULE, 'cancelTask', payload as unknown as Record<string, unknown>);
    return result as unknown as CancelTaskResult;
  }

  async cancelAllTasks(): Promise<CancelAllTasksResult> {
    const result = await this.bridge.call(MODULE, 'cancelAllTasks');
    return result as unknown as CancelAllTasksResult;
  }

  async getScheduledTasks(): Promise<GetScheduledTasksResult> {
    const result = await this.bridge.call(MODULE, 'getScheduledTasks');
    return result as unknown as GetScheduledTasksResult;
  }

  onTaskExecute(listener: (data: TaskExecuteEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as TaskExecuteEvent);
    this.bridge.onEvent('backgroundTask:taskExecute', wrapper);
    return () => this.bridge.offEvent('backgroundTask:taskExecute', wrapper);
  }

  completeTask(payload: CompleteTaskPayload): void {
    this.bridge.send(MODULE, 'completeTask', payload as unknown as Record<string, unknown>);
  }

  async requestPermission(): Promise<PermissionResult> {
    const result = await this.bridge.call(MODULE, 'requestPermission');
    return result as unknown as PermissionResult;
  }
}
