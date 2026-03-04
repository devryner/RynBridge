import { describe, it, expect } from 'vitest';
import { join } from 'node:path';
import { loadSchemas } from '../schema-loader.js';

const CONTRACTS_DIR = join(__dirname, '../../../../contracts');

describe('schema-loader', () => {
  it('loads all module schemas from contracts directory', () => {
    const schemas = loadSchemas(CONTRACTS_DIR);

    expect(Object.keys(schemas)).toContain('device');
    expect(Object.keys(schemas)).toContain('storage');
    expect(Object.keys(schemas)).toContain('ui');
    expect(Object.keys(schemas)).toContain('secure-storage');
    expect(Object.keys(schemas)).not.toContain('core');
  });

  it('groups actions correctly for device module', () => {
    const schemas = loadSchemas(CONTRACTS_DIR);
    const device = schemas['device'];

    const actionNames = device.map((a) => a.action).sort();
    expect(actionNames).toContain('getInfo');
    expect(actionNames).toContain('getBattery');
    expect(actionNames).toContain('vibrate');
    expect(actionNames).toContain('capturePhoto');
  });

  it('parses request and response schemas', () => {
    const schemas = loadSchemas(CONTRACTS_DIR);
    const device = schemas['device'];
    const getInfo = device.find((a) => a.action === 'getInfo')!;

    expect(getInfo.request.title).toBe('DeviceGetInfoRequest');
    expect(getInfo.response).toBeDefined();
    expect(getInfo.response!.title).toBe('DeviceGetInfoResponse');
    expect(getInfo.response!.properties).toHaveProperty('platform');
  });

  it('handles fire-and-forget actions (no response)', () => {
    const schemas = loadSchemas(CONTRACTS_DIR);
    const device = schemas['device'];
    const vibrate = device.find((a) => a.action === 'vibrate')!;

    expect(vibrate.request).toBeDefined();
    expect(vibrate.response).toBeUndefined();
  });

  it('throws for non-existent directory', () => {
    expect(() => loadSchemas('/non/existent/path')).toThrow(
      'Contracts directory not found',
    );
  });
});
