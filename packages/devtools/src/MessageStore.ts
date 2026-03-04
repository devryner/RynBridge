import type { MessageEntry, MessageStatus, StoreEvent, StoreListener } from './types.js';

export class MessageStore {
  private entries: MessageEntry[] = [];
  private listeners: Set<StoreListener> = new Set();

  add(entry: MessageEntry): void {
    this.entries.push(entry);
    this.emit({ type: 'add', entry });
  }

  update(id: string, patch: Partial<MessageEntry>): void {
    const entry = this.entries.find((e) => e.id === id);
    if (!entry) return;
    Object.assign(entry, patch);
    this.emit({ type: 'update', entry });
  }

  matchResponse(
    id: string,
    status: MessageStatus,
    responsePayload?: Record<string, unknown>,
    error?: { code: string; message: string },
  ): void {
    const entry = this.entries.find((e) => e.id === id && e.direction === 'outgoing');
    if (!entry) return;

    const latency = Date.now() - entry.timestamp;
    Object.assign(entry, { status, latency, responsePayload, error });
    this.emit({ type: 'update', entry });
  }

  getAll(): readonly MessageEntry[] {
    return this.entries;
  }

  getFiltered(filter: {
    module?: string;
    direction?: MessageEntry['direction'];
    status?: MessageStatus;
  }): MessageEntry[] {
    return this.entries.filter((e) => {
      if (filter.module && e.module !== filter.module) return false;
      if (filter.direction && e.direction !== filter.direction) return false;
      if (filter.status && e.status !== filter.status) return false;
      return true;
    });
  }

  getStats(): { count: number; avgLatency: number } {
    const withLatency = this.entries.filter((e) => e.latency !== undefined);
    const avgLatency =
      withLatency.length > 0
        ? withLatency.reduce((sum, e) => sum + e.latency!, 0) / withLatency.length
        : 0;
    return { count: this.entries.length, avgLatency: Math.round(avgLatency * 100) / 100 };
  }

  clear(): void {
    this.entries = [];
    this.emit({ type: 'clear' });
  }

  subscribe(listener: StoreListener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private emit(event: StoreEvent): void {
    for (const listener of this.listeners) {
      listener(event);
    }
  }
}
