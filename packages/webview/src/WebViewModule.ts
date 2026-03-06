import type { RynBridge } from '@rynbridge/core';
import type {
  OpenPayload,
  OpenResult,
  ClosePayload,
  SendMessagePayload,
  PostEventPayload,
  MessageEvent,
  CloseEvent,
  GetWebViewsResult,
  SetResultPayload,
} from './types.js';

const MODULE = 'webview';

export class WebViewModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async open(payload: OpenPayload): Promise<OpenResult> {
    const result = await this.bridge.call(MODULE, 'open', payload as unknown as Record<string, unknown>);
    return result as unknown as OpenResult;
  }

  async close(payload: ClosePayload): Promise<void> {
    await this.bridge.call(MODULE, 'close', payload as unknown as Record<string, unknown>);
  }

  async sendMessage(payload: SendMessagePayload): Promise<void> {
    await this.bridge.call(MODULE, 'sendMessage', payload as unknown as Record<string, unknown>);
  }

  postEvent(payload: PostEventPayload): void {
    this.bridge.send(MODULE, 'postEvent', payload as unknown as Record<string, unknown>);
  }

  onMessage(listener: (data: MessageEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as MessageEvent);
    this.bridge.onEvent('webview:message', wrapper);
    return () => this.bridge.offEvent('webview:message', wrapper);
  }

  onClose(listener: (data: CloseEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as CloseEvent);
    this.bridge.onEvent('webview:close', wrapper);
    return () => this.bridge.offEvent('webview:close', wrapper);
  }

  async getWebViews(): Promise<GetWebViewsResult> {
    const result = await this.bridge.call(MODULE, 'getWebViews');
    return result as unknown as GetWebViewsResult;
  }

  setResult(payload: SetResultPayload): void {
    this.bridge.send(MODULE, 'setResult', payload as unknown as Record<string, unknown>);
  }
}
