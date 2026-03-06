export interface RequestPermissionPayload {
  readTypes: string[];
  writeTypes?: string[];
}

export interface PermissionResult {
  granted: boolean;
}

export interface PermissionStatus {
  status: 'granted' | 'denied' | 'notDetermined';
}

export interface QueryDataPayload {
  dataType: string;
  startDate: string;
  endDate: string;
  limit?: number;
}

export interface HealthRecord {
  id: string;
  dataType: string;
  value: number;
  unit: string;
  startDate: string;
  endDate: string;
  sourceName: string | null;
}

export interface QueryDataResult {
  records: HealthRecord[];
}

export interface WriteDataPayload {
  dataType: string;
  value: number;
  unit: string;
  startDate: string;
  endDate: string;
}

export interface WriteDataResult {
  success: boolean;
}

export interface GetStepsPayload {
  startDate: string;
  endDate: string;
}

export interface GetStepsResult {
  steps: number;
}

export interface IsAvailableResult {
  available: boolean;
}

export interface DataChangeEvent {
  dataType: string;
}
