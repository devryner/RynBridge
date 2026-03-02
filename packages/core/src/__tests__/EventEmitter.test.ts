import { describe, it, expect, vi } from 'vitest';
import { EventEmitter } from '../event/EventEmitter.js';

describe('EventEmitter', () => {
  it('emits and receives events', () => {
    const emitter = new EventEmitter();
    const handler = vi.fn();

    emitter.on('test', handler);
    emitter.emit('test', { value: 1 });

    expect(handler).toHaveBeenCalledWith({ value: 1 });
  });

  it('supports multiple listeners', () => {
    const emitter = new EventEmitter();
    const h1 = vi.fn();
    const h2 = vi.fn();

    emitter.on('test', h1);
    emitter.on('test', h2);
    emitter.emit('test', { x: 1 });

    expect(h1).toHaveBeenCalledOnce();
    expect(h2).toHaveBeenCalledOnce();
  });

  it('removes a specific listener', () => {
    const emitter = new EventEmitter();
    const handler = vi.fn();

    emitter.on('test', handler);
    emitter.off('test', handler);
    emitter.emit('test', {});

    expect(handler).not.toHaveBeenCalled();
  });

  it('does not call removed listeners', () => {
    const emitter = new EventEmitter();
    const h1 = vi.fn();
    const h2 = vi.fn();

    emitter.on('test', h1);
    emitter.on('test', h2);
    emitter.off('test', h1);
    emitter.emit('test', {});

    expect(h1).not.toHaveBeenCalled();
    expect(h2).toHaveBeenCalledOnce();
  });

  it('does nothing when emitting with no listeners', () => {
    const emitter = new EventEmitter();
    expect(() => emitter.emit('nope', {})).not.toThrow();
  });

  it('removes all listeners for a specific event', () => {
    const emitter = new EventEmitter();
    const h1 = vi.fn();
    const h2 = vi.fn();

    emitter.on('a', h1);
    emitter.on('b', h2);
    emitter.removeAllListeners('a');
    emitter.emit('a', {});
    emitter.emit('b', {});

    expect(h1).not.toHaveBeenCalled();
    expect(h2).toHaveBeenCalledOnce();
  });

  it('removes all listeners', () => {
    const emitter = new EventEmitter();
    const h1 = vi.fn();
    const h2 = vi.fn();

    emitter.on('a', h1);
    emitter.on('b', h2);
    emitter.removeAllListeners();
    emitter.emit('a', {});
    emitter.emit('b', {});

    expect(h1).not.toHaveBeenCalled();
    expect(h2).not.toHaveBeenCalled();
  });

  it('reports listener count', () => {
    const emitter = new EventEmitter();
    expect(emitter.listenerCount('test')).toBe(0);

    const h = vi.fn();
    emitter.on('test', h);
    expect(emitter.listenerCount('test')).toBe(1);

    emitter.off('test', h);
    expect(emitter.listenerCount('test')).toBe(0);
  });
});
