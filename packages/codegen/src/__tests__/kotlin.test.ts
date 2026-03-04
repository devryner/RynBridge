import { describe, it, expect } from 'vitest';
import { generateKotlin } from '../generators/kotlin.js';
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
        level: { type: 'integer' },
        scale: { type: 'number' },
        isActive: { type: 'boolean' },
      },
      required: ['platform', 'osVersion', 'level', 'scale', 'isActive'],
    },
  },
  {
    action: 'capturePhoto',
    request: {
      title: 'DeviceCapturePhotoRequest',
      type: 'object',
      properties: {
        quality: { type: 'number' },
      },
    },
  },
];

describe('generateKotlin', () => {
  it('generates data class', () => {
    const output = generateKotlin({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('data class DeviceGetInfoResponse(');
  });

  it('maps types correctly', () => {
    const output = generateKotlin({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('val platform: String');
    expect(output).toContain('val level: Int');
    expect(output).toContain('val scale: Double');
    expect(output).toContain('val isActive: Boolean');
  });

  it('marks optional fields with nullable + default null', () => {
    const output = generateKotlin({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('val quality: Double? = null');
  });

  it('generates toPayload method', () => {
    const output = generateKotlin({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('fun toPayload(): Map<String, Any?>');
    expect(output).toContain('payload["platform"] = platform');
  });

  it('generates companion fromPayload', () => {
    const output = generateKotlin({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('companion object');
    expect(output).toContain('fun fromPayload(payload: Map<String, Any?>)');
  });

  it('includes package declaration', () => {
    const output = generateKotlin({ moduleName: 'device', actions: sampleActions });

    expect(output).toContain('package io.rynbridge.device.generated');
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
    const output = generateKotlin({ moduleName: 'storage', actions });
    expect(output).toContain('val files: List<String>');
  });
});
