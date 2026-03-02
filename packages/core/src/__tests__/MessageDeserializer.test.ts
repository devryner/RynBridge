import { describe, it, expect } from 'vitest';
import { MessageDeserializer } from '../message/MessageDeserializer.js';

describe('MessageDeserializer', () => {
  const deserializer = new MessageDeserializer();

  it('parses a success response', () => {
    const raw = JSON.stringify({
      id: 'abc-123',
      status: 'success',
      payload: { data: 42 },
      error: null,
    });

    const result = deserializer.deserialize(raw);
    expect(result.type).toBe('response');
    expect(result.data).toEqual({
      id: 'abc-123',
      status: 'success',
      payload: { data: 42 },
      error: null,
    });
  });

  it('parses an error response', () => {
    const raw = JSON.stringify({
      id: 'abc-456',
      status: 'error',
      payload: {},
      error: { code: 'TIMEOUT', message: 'timed out' },
    });

    const result = deserializer.deserialize(raw);
    expect(result.type).toBe('response');
    if (result.type === 'response') {
      expect(result.data.status).toBe('error');
      expect(result.data.error?.code).toBe('TIMEOUT');
    }
  });

  it('parses a request message', () => {
    const raw = JSON.stringify({
      id: 'req-1',
      module: 'device',
      action: 'getInfo',
      payload: {},
      version: '1.0.0',
    });

    const result = deserializer.deserialize(raw);
    expect(result.type).toBe('request');
    if (result.type === 'request') {
      expect(result.data.module).toBe('device');
      expect(result.data.action).toBe('getInfo');
    }
  });

  it('throws on invalid JSON', () => {
    expect(() => deserializer.deserialize('not json')).toThrow(/parse/i);
  });

  it('throws on non-object', () => {
    expect(() => deserializer.deserialize('"string"')).toThrow(/object/i);
  });

  it('throws on missing id', () => {
    const raw = JSON.stringify({ status: 'success', payload: {} });
    expect(() => deserializer.deserialize(raw)).toThrow(/id/i);
  });

  it('throws on invalid status', () => {
    const raw = JSON.stringify({ id: '1', status: 'maybe', payload: {} });
    expect(() => deserializer.deserialize(raw)).toThrow(/status/i);
  });

  it('throws when neither response nor request', () => {
    const raw = JSON.stringify({ id: '1', foo: 'bar' });
    expect(() => deserializer.deserialize(raw)).toThrow(/request.*response|response.*request/i);
  });

  it('defaults missing payload in request', () => {
    const raw = JSON.stringify({
      id: 'req-2',
      module: 'test',
      action: 'ping',
      version: '1.0.0',
    });

    const result = deserializer.deserialize(raw);
    if (result.type === 'request') {
      expect(result.data.payload).toEqual({});
    }
  });
});
