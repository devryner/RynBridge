import { describe, it, expect, vi } from 'vitest';
import { MessageStore } from '../MessageStore.js';
import type { MessageEntry } from '../types.js';

function makeEntry(overrides: Partial<MessageEntry> = {}): MessageEntry {
  return {
    id: 'test-id',
    direction: 'outgoing',
    module: 'device',
    action: 'getInfo',
    payload: {},
    status: 'pending',
    timestamp: Date.now(),
    ...overrides,
  };
}

describe('MessageStore', () => {
  it('adds and retrieves entries', () => {
    const store = new MessageStore();
    const entry = makeEntry();
    store.add(entry);

    expect(store.getAll()).toHaveLength(1);
    expect(store.getAll()[0]).toBe(entry);
  });

  it('matches response to outgoing request', () => {
    const store = new MessageStore();
    store.add(makeEntry({ id: 'req-1', timestamp: Date.now() - 50 }));

    store.matchResponse('req-1', 'success', { platform: 'ios' });

    const entries = store.getAll();
    expect(entries[0].status).toBe('success');
    expect(entries[0].responsePayload).toEqual({ platform: 'ios' });
    expect(entries[0].latency).toBeGreaterThanOrEqual(0);
  });

  it('does not match response for unknown id', () => {
    const store = new MessageStore();
    store.add(makeEntry({ id: 'req-1' }));

    store.matchResponse('unknown', 'success', {});

    expect(store.getAll()[0].status).toBe('pending');
  });

  it('filters by module', () => {
    const store = new MessageStore();
    store.add(makeEntry({ id: '1', module: 'device' }));
    store.add(makeEntry({ id: '2', module: 'storage' }));

    expect(store.getFiltered({ module: 'device' })).toHaveLength(1);
    expect(store.getFiltered({ module: 'storage' })).toHaveLength(1);
  });

  it('filters by direction', () => {
    const store = new MessageStore();
    store.add(makeEntry({ id: '1', direction: 'outgoing' }));
    store.add(makeEntry({ id: '2', direction: 'incoming' }));

    expect(store.getFiltered({ direction: 'outgoing' })).toHaveLength(1);
    expect(store.getFiltered({ direction: 'incoming' })).toHaveLength(1);
  });

  it('filters by status', () => {
    const store = new MessageStore();
    store.add(makeEntry({ id: '1', status: 'pending' }));
    store.add(makeEntry({ id: '2', status: 'success' }));

    expect(store.getFiltered({ status: 'pending' })).toHaveLength(1);
    expect(store.getFiltered({ status: 'success' })).toHaveLength(1);
  });

  it('calculates stats', () => {
    const store = new MessageStore();
    store.add(makeEntry({ id: '1', latency: 10 }));
    store.add(makeEntry({ id: '2', latency: 20 }));
    store.add(makeEntry({ id: '3' }));

    const stats = store.getStats();
    expect(stats.count).toBe(3);
    expect(stats.avgLatency).toBe(15);
  });

  it('clears all entries', () => {
    const store = new MessageStore();
    store.add(makeEntry());
    store.clear();

    expect(store.getAll()).toHaveLength(0);
  });

  it('notifies subscribers on add', () => {
    const store = new MessageStore();
    const listener = vi.fn();
    store.subscribe(listener);

    const entry = makeEntry();
    store.add(entry);

    expect(listener).toHaveBeenCalledWith({ type: 'add', entry });
  });

  it('notifies subscribers on clear', () => {
    const store = new MessageStore();
    const listener = vi.fn();
    store.subscribe(listener);

    store.clear();

    expect(listener).toHaveBeenCalledWith({ type: 'clear' });
  });

  it('unsubscribes correctly', () => {
    const store = new MessageStore();
    const listener = vi.fn();
    const unsub = store.subscribe(listener);

    unsub();
    store.add(makeEntry());

    expect(listener).not.toHaveBeenCalled();
  });
});
