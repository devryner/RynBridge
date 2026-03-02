export interface BridgeRequest {
  id: string;
  module: string;
  action: string;
  payload: Record<string, unknown>;
  version: string;
}

export interface BridgeResponse {
  id: string;
  status: 'success' | 'error';
  payload: Record<string, unknown>;
  error: BridgeErrorData | null;
}

export interface BridgeErrorData {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export interface BridgeConfig {
  timeout?: number;
  version?: string;
}

export const DEFAULT_CONFIG: Required<BridgeConfig> = {
  timeout: 30_000,
  version: '0.1.0',
};

export interface BridgeModule {
  name: string;
  version: string;
  actions: Record<string, ActionHandler>;
}

export type ActionHandler = (
  payload: Record<string, unknown>,
) => Promise<Record<string, unknown>> | Record<string, unknown>;

export interface BridgeHost {
  call(
    module: string,
    action: string,
    payload?: Record<string, unknown>,
  ): Promise<Record<string, unknown>>;
  send(
    module: string,
    action: string,
    payload?: Record<string, unknown>,
  ): void;
}

export interface Transport {
  send(message: string): void;
  onMessage(handler: (message: string) => void): void;
  dispose(): void;
}
