import { ErrorCode, RynBridgeError } from '../errors.js';

export function withTimeout<T>(
  promise: Promise<T>,
  ms: number,
  requestId?: string,
): Promise<T> {
  let timer: ReturnType<typeof setTimeout>;

  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      reject(
        new RynBridgeError(ErrorCode.TIMEOUT, `Request timed out after ${ms}ms`, {
          timeoutMs: ms,
          ...(requestId ? { requestId } : {}),
        }),
      );
    }, ms);
  });

  return Promise.race([promise, timeout]).finally(() => {
    clearTimeout(timer);
  });
}
