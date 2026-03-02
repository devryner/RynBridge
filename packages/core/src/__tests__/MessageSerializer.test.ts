import { describe, it, expect } from 'vitest';
import { MessageSerializer } from '../message/MessageSerializer.js';

describe('MessageSerializer', () => {
  const serializer = new MessageSerializer('0.1.0');

  it('creates a request with correct fields', () => {
    const request = serializer.createRequest('device', 'getInfo', { key: 'value' });

    expect(request.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
    expect(request.module).toBe('device');
    expect(request.action).toBe('getInfo');
    expect(request.payload).toEqual({ key: 'value' });
    expect(request.version).toBe('0.1.0');
  });

  it('defaults payload to empty object', () => {
    const request = serializer.createRequest('device', 'ping');
    expect(request.payload).toEqual({});
  });

  it('serializes a request to JSON', () => {
    const request = serializer.createRequest('storage', 'get', { key: 'foo' });
    const json = serializer.serialize(request);
    const parsed = JSON.parse(json);

    expect(parsed.id).toBe(request.id);
    expect(parsed.module).toBe('storage');
    expect(parsed.action).toBe('get');
    expect(parsed.payload).toEqual({ key: 'foo' });
    expect(parsed.version).toBe('0.1.0');
  });

  it('generates unique IDs', () => {
    const ids = new Set(
      Array.from({ length: 100 }, () => serializer.createRequest('m', 'a').id),
    );
    expect(ids.size).toBe(100);
  });
});
