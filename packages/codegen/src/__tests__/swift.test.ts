import { describe, it, expect } from 'vitest';
import { generateSwift } from '../generators/swift.js';
import type { ActionSchema } from '../types.js';

const sampleActions: ActionSchema[] = [
  {
    action: 'getInfo',
    request: {
      title: 'DeviceGetInfoRequest',
      type: 'object',
      properties: {},
    },
    response: {
      title: 'DeviceGetInfoResponse',
      type: 'object',
      properties: {
        platform: { type: 'string' },
        osVersion: { type: 'string' },
        model: { type: 'string' },
        level: { type: 'integer' },
      },
      required: ['platform', 'osVersion', 'model', 'level'],
    },
  },
  {
    action: 'capturePhoto',
    request: {
      title: 'DeviceCapturePhotoRequest',
      type: 'object',
      properties: {
        quality: { type: 'number' },
        camera: { type: 'string', enum: ['front', 'back'] },
      },
    },
  },
];

describe('generateSwift', () => {
  it('generates struct with Sendable conformance', () => {
    const output = generateSwift({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('public struct DeviceGetInfoResponse: Sendable');
  });

  it('maps types correctly', () => {
    const output = generateSwift({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('public let platform: String');
    expect(output).toContain('public let level: Int');
  });

  it('marks optional fields', () => {
    const output = generateSwift({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('public let quality: Double?');
    expect(output).toContain('public let camera: String?');
  });

  it('generates init method', () => {
    const output = generateSwift({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('public init(');
    expect(output).toContain('self.platform = platform');
  });

  it('generates toPayload method', () => {
    const output = generateSwift({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('public func toPayload() -> [String: Any]');
    expect(output).toContain('payload["platform"] = platform');
  });

  it('generates init from payload', () => {
    const output = generateSwift({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('public init(from payload: [String: Any])');
  });

  it('includes import Foundation', () => {
    const output = generateSwift({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('import Foundation');
  });

  it('handles array types', () => {
    const actions: ActionSchema[] = [
      {
        action: 'listDir',
        request: { title: 'ListDirRequest', type: 'object', properties: {} },
        response: {
          title: 'ListDirResponse',
          type: 'object',
          properties: {
            files: { type: 'array', items: { type: 'string' } },
          },
          required: ['files'],
        },
      },
    ];
    const output = generateSwift({ moduleName: 'storage', actions });
    expect(output).toContain('public let files: [String]');
  });
});
