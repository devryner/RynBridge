import { describe, it, expect, afterEach } from 'vitest';
import { RynBridge } from '../RynBridge.js';

describe('RynBridge.shared', () => {
  afterEach(() => {
    RynBridge.resetShared();
  });

  it('returns the same instance on repeated access', () => {
    const a = RynBridge.shared;
    const b = RynBridge.shared;
    expect(a).toBe(b);
  });

  it('creates a new instance after resetShared()', () => {
    const a = RynBridge.shared;
    RynBridge.resetShared();
    const b = RynBridge.shared;
    expect(a).not.toBe(b);
  });

  it('is an instance of RynBridge', () => {
    expect(RynBridge.shared).toBeInstanceOf(RynBridge);
  });
});
