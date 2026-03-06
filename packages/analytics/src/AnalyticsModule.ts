import type { RynBridge } from '@rynbridge/core';
import type {
  LogEventPayload,
  SetUserPropertyPayload,
  SetUserIdPayload,
  SetScreenPayload,
  SetEnabledPayload,
  IsEnabledResult,
} from './types.js';

const MODULE = 'analytics';

export class AnalyticsModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  logEvent(payload: LogEventPayload): void {
    this.bridge.send(MODULE, 'logEvent', payload as unknown as Record<string, unknown>);
  }

  setUserProperty(payload: SetUserPropertyPayload): void {
    this.bridge.send(MODULE, 'setUserProperty', payload as unknown as Record<string, unknown>);
  }

  setUserId(payload: SetUserIdPayload): void {
    this.bridge.send(MODULE, 'setUserId', payload as unknown as Record<string, unknown>);
  }

  setScreen(payload: SetScreenPayload): void {
    this.bridge.send(MODULE, 'setScreen', payload as unknown as Record<string, unknown>);
  }

  resetUser(): void {
    this.bridge.send(MODULE, 'resetUser', {});
  }

  async setEnabled(payload: SetEnabledPayload): Promise<IsEnabledResult> {
    const result = await this.bridge.call(MODULE, 'setEnabled', payload as unknown as Record<string, unknown>);
    return result as unknown as IsEnabledResult;
  }

  async isEnabled(): Promise<IsEnabledResult> {
    const result = await this.bridge.call(MODULE, 'isEnabled');
    return result as unknown as IsEnabledResult;
  }
}
