import type { Transport } from '../types.js';

export class MockTransport implements Transport {
  readonly sent: string[] = [];
  private handler: ((message: string) => void) | null = null;

  send(message: string): void {
    this.sent.push(message);
  }

  onMessage(handler: (message: string) => void): void {
    this.handler = handler;
  }

  simulateIncoming(message: string): void {
    this.handler?.(message);
  }

  dispose(): void {
    this.handler = null;
  }
}
