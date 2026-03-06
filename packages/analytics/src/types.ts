export interface LogEventPayload {
  name: string;
  params?: Record<string, unknown>;
}

export interface SetUserPropertyPayload {
  key: string;
  value: string;
}

export interface SetUserIdPayload {
  userId: string;
}

export interface SetScreenPayload {
  name: string;
}

export interface SetEnabledPayload {
  enabled: boolean;
}

export interface IsEnabledResult {
  enabled: boolean;
}
