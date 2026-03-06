export interface ScheduleTaskPayload {
  taskId: string;
  type: 'oneTime' | 'periodic' | 'connectivity';
  interval?: number;
  delay?: number;
  requiresNetwork?: boolean;
  requiresCharging?: boolean;
}

export interface ScheduleTaskResult {
  taskId: string;
  success: boolean;
}

export interface CancelTaskPayload {
  taskId: string;
}

export interface CancelTaskResult {
  success: boolean;
}

export interface CancelAllTasksResult {
  success: boolean;
}

export interface ScheduledTask {
  taskId: string;
  type: 'oneTime' | 'periodic' | 'connectivity';
  interval: number | null;
  requiresNetwork: boolean;
  requiresCharging: boolean;
}

export interface GetScheduledTasksResult {
  tasks: ScheduledTask[];
}

export interface TaskExecuteEvent {
  taskId: string;
}

export interface CompleteTaskPayload {
  taskId: string;
  success: boolean;
}

export interface PermissionResult {
  granted: boolean;
}
