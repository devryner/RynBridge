import { describe, it, expect, vi } from 'vitest';
import { CallbackRegistry } from '../callback/CallbackRegistry.js';
import type { BridgeResponse } from '../types.js';
import { RynBridgeError, ErrorCode } from '../errors.js';

function makeResponse(id: string, status: 'success' | 'error' = 'success'): BridgeResponse {
  return { id, status, payload: { result: 'ok' }, error: null };
}

describe('CallbackRegistry', () => {
  it('registers and resolves a callback', async () => {
    const registry = new CallbackRegistry();
    const promise = registry.register('req-1', 5000);

    expect(registry.has('req-1')).toBe(true);
    expect(registry.size).toBe(1);

    const response = makeResponse('req-1');
    registry.resolve('req-1', response);

    const result = await promise;
    expect(result).toEqual(response);
    expect(registry.has('req-1')).toBe(false);
  });

  it('rejects a callback', async () => {
    const registry = new CallbackRegistry();
    const promise = registry.register('req-2', 5000);

    const error = new RynBridgeError(ErrorCode.UNKNOWN, 'test error');
    registry.reject('req-2', error);

    await expect(promise).rejects.toThrow('test error');
    expect(registry.has('req-2')).toBe(false);
  });

  it('returns false when resolving unknown id', () => {
    const registry = new CallbackRegistry();
    expect(registry.resolve('unknown', makeResponse('unknown'))).toBe(false);
  });

  it('returns false when rejecting unknown id', () => {
    const registry = new CallbackRegistry();
    const error = new RynBridgeError(ErrorCode.UNKNOWN, 'err');
    expect(registry.reject('unknown', error)).toBe(false);
  });

  it('times out and rejects', async () => {
    vi.useFakeTimers();
    const registry = new CallbackRegistry();
    const promise = registry.register('req-3', 100);

    vi.advanceTimersByTime(100);

    await expect(promise).rejects.toThrow(/timed out/);
    expect(registry.has('req-3')).toBe(false);
    vi.useRealTimers();
  });

  it('clears all pending callbacks', async () => {
    const registry = new CallbackRegistry();
    const p1 = registry.register('a', 5000);
    const p2 = registry.register('b', 5000);

    expect(registry.size).toBe(2);
    registry.clear();

    await expect(p1).rejects.toThrow(/disposed/);
    await expect(p2).rejects.toThrow(/disposed/);
    expect(registry.size).toBe(0);
  });
});
