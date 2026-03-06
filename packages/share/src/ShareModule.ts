import type { RynBridge } from '@rynbridge/core';
import type {
  SharePayload,
  ShareFilePayload,
  ShareResult,
  ClipboardText,
  CanShareResult,
} from './types.js';

const MODULE = 'share';

export class ShareModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async share(payload: SharePayload): Promise<ShareResult> {
    const result = await this.bridge.call(MODULE, 'share', payload as unknown as Record<string, unknown>);
    return result as unknown as ShareResult;
  }

  async shareFile(payload: ShareFilePayload): Promise<ShareResult> {
    const result = await this.bridge.call(MODULE, 'shareFile', payload as unknown as Record<string, unknown>);
    return result as unknown as ShareResult;
  }

  copyToClipboard(payload: ClipboardText): void {
    this.bridge.send(MODULE, 'copyToClipboard', payload as unknown as Record<string, unknown>);
  }

  async readClipboard(): Promise<ClipboardText> {
    const result = await this.bridge.call(MODULE, 'readClipboard');
    return result as unknown as ClipboardText;
  }

  async canShare(): Promise<CanShareResult> {
    const result = await this.bridge.call(MODULE, 'canShare');
    return result as unknown as CanShareResult;
  }
}
