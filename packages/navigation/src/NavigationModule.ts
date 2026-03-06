import type { RynBridge } from '@rynbridge/core';
import type {
  PushPayload,
  PopResult,
  PresentPayload,
  OpenURLPayload,
  OpenURLResult,
  CanOpenURLPayload,
  CanOpenURLResult,
  InitialURLResult,
  DeepLinkEvent,
  AppState,
  AppStateChangeEvent,
} from './types.js';

const MODULE = 'navigation';

export class NavigationModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async push(payload: PushPayload): Promise<PopResult> {
    const result = await this.bridge.call(MODULE, 'push', payload as unknown as Record<string, unknown>);
    return result as unknown as PopResult;
  }

  async pop(): Promise<PopResult> {
    const result = await this.bridge.call(MODULE, 'pop');
    return result as unknown as PopResult;
  }

  async popToRoot(): Promise<PopResult> {
    const result = await this.bridge.call(MODULE, 'popToRoot');
    return result as unknown as PopResult;
  }

  async present(payload: PresentPayload): Promise<PopResult> {
    const result = await this.bridge.call(MODULE, 'present', payload as unknown as Record<string, unknown>);
    return result as unknown as PopResult;
  }

  async dismiss(): Promise<PopResult> {
    const result = await this.bridge.call(MODULE, 'dismiss');
    return result as unknown as PopResult;
  }

  async openURL(payload: OpenURLPayload): Promise<OpenURLResult> {
    const result = await this.bridge.call(MODULE, 'openURL', payload as unknown as Record<string, unknown>);
    return result as unknown as OpenURLResult;
  }

  async canOpenURL(payload: CanOpenURLPayload): Promise<CanOpenURLResult> {
    const result = await this.bridge.call(MODULE, 'canOpenURL', payload as unknown as Record<string, unknown>);
    return result as unknown as CanOpenURLResult;
  }

  async getInitialURL(): Promise<InitialURLResult> {
    const result = await this.bridge.call(MODULE, 'getInitialURL');
    return result as unknown as InitialURLResult;
  }

  async getAppState(): Promise<AppState> {
    const result = await this.bridge.call(MODULE, 'getAppState');
    return result as unknown as AppState;
  }

  onDeepLink(listener: (data: DeepLinkEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as DeepLinkEvent);
    this.bridge.onEvent('navigation:deepLink', wrapper);
    return () => this.bridge.offEvent('navigation:deepLink', wrapper);
  }

  onAppStateChange(listener: (data: AppStateChangeEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as AppStateChangeEvent);
    this.bridge.onEvent('navigation:appStateChange', wrapper);
    return () => this.bridge.offEvent('navigation:appStateChange', wrapper);
  }
}
