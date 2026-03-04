import type { RynBridge } from '@rynbridge/core';
import type {
  ShowAlertPayload,
  ShowConfirmPayload,
  ShowConfirmResponse,
  ShowToastPayload,
  ShowActionSheetPayload,
  ShowActionSheetResponse,
  SetStatusBarPayload,
  KeyboardHeightResponse,
  KeyboardChangeInfo,
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

  showKeyboard(): void {
    this.bridge.send(MODULE, 'showKeyboard');
  }

  hideKeyboard(): void {
    this.bridge.send(MODULE, 'hideKeyboard');
  }

  async getKeyboardHeight(): Promise<KeyboardHeightResponse> {
    const result = await this.bridge.call(MODULE, 'getKeyboardHeight');
    return result as unknown as KeyboardHeightResponse;
  }

  onKeyboardChange(listener: (data: KeyboardChangeInfo) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as KeyboardChangeInfo);
    this.bridge.onEvent('ui:keyboardChange', wrapper);
    return () => this.bridge.offEvent('ui:keyboardChange', wrapper);
  }
}
