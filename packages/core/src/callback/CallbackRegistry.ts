import type { BridgeResponse } from '../types.js';
import { ErrorCode, RynBridgeError } from '../errors.js';

interface PendingCallback {
  resolve: (response: BridgeResponse) => void;
  reject: (error: RynBridgeError) => void;
  timer: ReturnType<typeof setTimeout>;
}

export class CallbackRegistry {
  private readonly pending = new Map<string, PendingCallback>();

  register(id: string, timeoutMs: number): Promise<BridgeResponse> {
    return new Promise<BridgeResponse>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(
          new RynBridgeError(ErrorCode.TIMEOUT, `Request ${id} timed out after ${timeoutMs}ms`, {
            requestId: id,
            timeoutMs,
          }),
        );
      }, timeoutMs);

      this.pending.set(id, { resolve, reject, timer });
    });
  }

  resolve(id: string, response: BridgeResponse): boolean {
    const cb = this.pending.get(id);
    if (!cb) return false;

    clearTimeout(cb.timer);
    this.pending.delete(id);
    cb.resolve(response);
    return true;
  }

  reject(id: string, error: RynBridgeError): boolean {
    const cb = this.pending.get(id);
    if (!cb) return false;

    clearTimeout(cb.timer);
    this.pending.delete(id);
    cb.reject(error);
    return true;
  }

  has(id: string): boolean {
    return this.pending.has(id);
  }

  get size(): number {
    return this.pending.size;
  }

  clear(): void {
    for (const [id, cb] of this.pending) {
      clearTimeout(cb.timer);
      cb.reject(
        new RynBridgeError(ErrorCode.UNKNOWN, 'Bridge disposed, all pending requests cancelled', {
          requestId: id,
        }),
      );
    }
    this.pending.clear();
  }
}
