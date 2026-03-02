export const ErrorCode = {
  TIMEOUT: 'TIMEOUT',
  MODULE_NOT_FOUND: 'MODULE_NOT_FOUND',
  ACTION_NOT_FOUND: 'ACTION_NOT_FOUND',
  INVALID_MESSAGE: 'INVALID_MESSAGE',
  SERIALIZATION_ERROR: 'SERIALIZATION_ERROR',
  TRANSPORT_ERROR: 'TRANSPORT_ERROR',
  VERSION_MISMATCH: 'VERSION_MISMATCH',
  UNKNOWN: 'UNKNOWN',
} as const;

export type ErrorCodeType = (typeof ErrorCode)[keyof typeof ErrorCode];

export class RynBridgeError extends Error {
  readonly code: ErrorCodeType;
  readonly details: Record<string, unknown>;

  constructor(
    code: ErrorCodeType,
    message: string,
    details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = 'RynBridgeError';
    this.code = code;
    this.details = details;
  }

  toJSON() {
    return {
      code: this.code,
      message: this.message,
      details: this.details,
    };
  }
}
