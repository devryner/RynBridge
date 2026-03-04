import { describe, it, expect, vi } from 'vitest';
import { DevToolsTransport } from '../DevToolsTransport.js';
import { MessageStore } from '../MessageStore.js';
import type { Transport } from '@rynbridge/core';

function createMockTransport(): Transport & { handlers: Array<(msg: string) => void> } {
  const handlers: Array<(msg: string) => void> = [];
  return {
    handlers,
    send: vi.fn(),
    onMessage: (handler: (msg: string) => void) => {
      handlers.push(handler);
    },
    dispose: vi.fn(),
  };
}

describe('DevToolsTransport', () => {
  it('delegates send to inner transport', () => {
    const inner = createMockTransport();
    const dt = new DevToolsTransport(inner);
    const msg = JSON.stringify({ id: '1', module: 'device', action: 'getInfo', payload: {}, version: '1.0.0' });

    dt.send(msg);

    expect(inner.send).toHaveBeenCalledWith(msg);
  });

  it('records outgoing messages in store', () => {
    const inner = createMockTransport();
    const dt = new DevToolsTransport(inner);
    const msg = JSON.stringify({ id: '1', module: 'device', action: 'getInfo', payload: {}, version: '1.0.0' });

    dt.send(msg);

    const entries = dt.store.getAll();
    expect(entries).toHaveLength(1);
    expect(entries[0].direction).toBe('outgoing');
    expect(entries[0].module).toBe('device');
    expect(entries[0].action).toBe('getInfo');
    expect(entries[0].status).toBe('pending');
  });

  it('matches incoming responses to outgoing requests', () => {
    const inner = createMockTransport();
    const dt = new DevToolsTransport(inner);
    const handler = vi.fn();
    dt.onMessage(handler);

    // Send outgoing
    dt.send(JSON.stringify({ id: 'r1', module: 'device', action: 'getInfo', payload: {}, version: '1.0.0' }));

    // Simulate incoming response
    const response = JSON.stringify({ id: 'r1', status: 'success', payload: { platform: 'ios' }, error: null });
    inner.handlers[0](response);

    expect(handler).toHaveBeenCalledWith(response);
    const entries = dt.store.getAll();
    expect(entries[0].status).toBe('success');
    expect(entries[0].responsePayload).toEqual({ platform: 'ios' });
  });

  it('records incoming events from native', () => {
    const inner = createMockTransport();
    const dt = new DevToolsTransport(inner);
    const handler = vi.fn();
    dt.onMessage(handler);

    const event = JSON.stringify({ id: 'e1', module: 'device', action: 'batteryChange', payload: { level: 80 } });
    inner.handlers[0](event);

    const entries = dt.store.getAll();
    expect(entries).toHaveLength(1);
    expect(entries[0].direction).toBe('incoming');
    expect(entries[0].module).toBe('device');
  });

  it('delegates dispose to inner transport', () => {
    const inner = createMockTransport();
    const dt = new DevToolsTransport(inner);

    dt.dispose();

    expect(inner.dispose).toHaveBeenCalled();
  });

  it('accepts custom store', () => {
    const inner = createMockTransport();
    const store = new MessageStore();
    const dt = new DevToolsTransport(inner, store);

    expect(dt.store).toBe(store);
  });

  it('handles non-JSON messages gracefully', () => {
    const inner = createMockTransport();
    const dt = new DevToolsTransport(inner);

    expect(() => dt.send('not json')).not.toThrow();
    expect(inner.send).toHaveBeenCalledWith('not json');
  });
});
