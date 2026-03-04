export type MessageDirection = 'outgoing' | 'incoming';
export type MessageStatus = 'pending' | 'success' | 'error' | 'timeout';

export interface MessageEntry {
  id: string;
  direction: MessageDirection;
  module: string;
  action: string;
  payload: Record<string, unknown>;
  status: MessageStatus;
  timestamp: number;
  latency?: number;
  responsePayload?: Record<string, unknown>;
  error?: { code: string; message: string };
}

export type StoreEvent =
  | { type: 'add'; entry: MessageEntry }
  | { type: 'update'; entry: MessageEntry }
  | { type: 'clear' };

export type StoreListener = (event: StoreEvent) => void;
