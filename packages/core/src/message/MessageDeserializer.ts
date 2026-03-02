import type { BridgeRequest, BridgeResponse } from '../types.js';
import { ErrorCode, RynBridgeError } from '../errors.js';

export type IncomingMessage =
  | { type: 'response'; data: BridgeResponse }
  | { type: 'request'; data: BridgeRequest };

export class MessageDeserializer {
  deserialize(raw: string): IncomingMessage {
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      throw new RynBridgeError(
        ErrorCode.INVALID_MESSAGE,
        'Failed to parse message JSON',
        { raw },
      );
    }

    if (typeof parsed !== 'object' || parsed === null) {
      throw new RynBridgeError(
        ErrorCode.INVALID_MESSAGE,
        'Message must be a JSON object',
        { raw },
      );
    }

    const msg = parsed as Record<string, unknown>;

    if (typeof msg['id'] !== 'string') {
      throw new RynBridgeError(
        ErrorCode.INVALID_MESSAGE,
        'Message must have a string "id" field',
        { raw },
      );
    }

    if ('status' in msg) {
      return { type: 'response', data: this.validateResponse(msg) };
    }

    if ('module' in msg && 'action' in msg) {
      return { type: 'request', data: this.validateRequest(msg) };
    }

    throw new RynBridgeError(
      ErrorCode.INVALID_MESSAGE,
      'Message must be a request (module+action) or response (status)',
      { raw },
    );
  }

  private validateResponse(msg: Record<string, unknown>): BridgeResponse {
    const status = msg['status'];
    if (status !== 'success' && status !== 'error') {
      throw new RynBridgeError(
        ErrorCode.INVALID_MESSAGE,
        'Response status must be "success" or "error"',
      );
    }

    return {
      id: msg['id'] as string,
      status,
      payload: (typeof msg['payload'] === 'object' && msg['payload'] !== null
        ? msg['payload']
        : {}) as Record<string, unknown>,
      error: msg['error'] as BridgeResponse['error'] ?? null,
    };
  }

  private validateRequest(msg: Record<string, unknown>): BridgeRequest {
    if (typeof msg['module'] !== 'string' || msg['module'].length === 0) {
      throw new RynBridgeError(
        ErrorCode.INVALID_MESSAGE,
        'Request must have a non-empty "module" field',
      );
    }
    if (typeof msg['action'] !== 'string' || msg['action'].length === 0) {
      throw new RynBridgeError(
        ErrorCode.INVALID_MESSAGE,
        'Request must have a non-empty "action" field',
      );
    }

    return {
      id: msg['id'] as string,
      module: msg['module'] as string,
      action: msg['action'] as string,
      payload: (typeof msg['payload'] === 'object' && msg['payload'] !== null
        ? msg['payload']
        : {}) as Record<string, unknown>,
      version: (typeof msg['version'] === 'string' ? msg['version'] : '0.0.0'),
    };
  }
}
