import type { Transport } from '@rynbridge/core';
import { MessageStore } from './MessageStore.js';

export class DevToolsTransport implements Transport {
  public readonly store: MessageStore;
  private readonly inner: Transport;

  constructor(inner: Transport, store?: MessageStore) {
    this.inner = inner;
    this.store = store ?? new MessageStore();
  }

  send(message: string): void {
    try {
      const parsed = JSON.parse(message);
      if (parsed.module && parsed.action) {
        this.store.add({
          id: parsed.id,
          direction: 'outgoing',
          module: parsed.module,
          action: parsed.action,
          payload: parsed.payload ?? {},
          status: 'pending',
          timestamp: Date.now(),
        });
      }
    } catch {
      // Not valid JSON, pass through
    }

    this.inner.send(message);
  }

  onMessage(handler: (message: string) => void): void {
    this.inner.onMessage((message: string) => {
      try {
        const parsed = JSON.parse(message);
        if (parsed.id && parsed.status !== undefined) {
          // This is a response
          const status = parsed.status === 'success' ? 'success' : 'error';
          this.store.matchResponse(
            parsed.id,
            status,
            parsed.payload,
            parsed.error ?? undefined,
          );
        } else if (parsed.module && parsed.action) {
          // This is an incoming event/request from native
          this.store.add({
            id: parsed.id ?? crypto.randomUUID(),
            direction: 'incoming',
            module: parsed.module,
            action: parsed.action,
            payload: parsed.payload ?? {},
            status: 'success',
            timestamp: Date.now(),
          });
        }
      } catch {
        // Not valid JSON, pass through
      }

      handler(message);
    });
  }

  dispose(): void {
    this.inner.dispose();
  }
}
