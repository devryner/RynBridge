import type { RynBridge } from '@rynbridge/core';
import type {
  ShowAlertPayload,
  ShowConfirmPayload,
  ShowConfirmResponse,
  ShowToastPayload,
  ShowActionSheetPayload,
  ShowActionSheetResponse,
  SetStatusBarPayload,
} from './types.js';

const MODULE = 'ui';

export class UIModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async showAlert(payload: ShowAlertPayload): Promise<void> {
    await this.bridge.call(MODULE, 'showAlert', payload as unknown as Record<string, unknown>);
  }

  async showConfirm(payload: ShowConfirmPayload): Promise<boolean> {
    const result = await this.bridge.call(
      MODULE,
      'showConfirm',
      payload as unknown as Record<string, unknown>,
    );
    return (result as unknown as ShowConfirmResponse).confirmed;
  }

  showToast(payload: ShowToastPayload): void {
    this.bridge.send(MODULE, 'showToast', payload as unknown as Record<string, unknown>);
  }

  async showActionSheet(payload: ShowActionSheetPayload): Promise<number> {
    const result = await this.bridge.call(
      MODULE,
      'showActionSheet',
      payload as unknown as Record<string, unknown>,
    );
    return (result as unknown as ShowActionSheetResponse).selectedIndex;
  }

  async setStatusBar(payload: SetStatusBarPayload): Promise<void> {
    await this.bridge.call(MODULE, 'setStatusBar', payload as unknown as Record<string, unknown>);
  }
}
