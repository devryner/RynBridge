import type { BridgeRequest } from '../types.js';
import { generateId } from '../util/uuid.js';
import { ErrorCode, RynBridgeError } from '../errors.js';

export class MessageSerializer {
  private readonly version: string;

  constructor(version: string) {
    this.version = version;
  }

  createRequest(
    module: string,
    action: string,
    payload: Record<string, unknown> = {},
  ): BridgeRequest {
    return {
      id: generateId(),
      module,
      action,
      payload,
      version: this.version,
    };
  }

  serialize(request: BridgeRequest): string {
    try {
      return JSON.stringify(request);
    } catch (error) {
      throw new RynBridgeError(
        ErrorCode.SERIALIZATION_ERROR,
        'Failed to serialize message',
        { originalError: String(error) },
      );
    }
  }
}
