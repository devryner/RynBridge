import { RynBridge } from '@rynbridge/core';
import type {
  ShareFeedPayload,
  ShareCommercePayload,
  ShareListPayload,
  ShareCustomPayload,
  KakaoShareResult,
  KakaoShareAvailability,
} from './types.js';

const MODULE = 'kakaoShare';

export class KakaoShareModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async shareFeed(payload: ShareFeedPayload): Promise<KakaoShareResult> {
    const result = await this.bridge.call(MODULE, 'shareFeed', payload as unknown as Record<string, unknown>);
    return result as unknown as KakaoShareResult;
  }

  async shareCommerce(payload: ShareCommercePayload): Promise<KakaoShareResult> {
    const result = await this.bridge.call(MODULE, 'shareCommerce', payload as unknown as Record<string, unknown>);
    return result as unknown as KakaoShareResult;
  }

  async shareList(payload: ShareListPayload): Promise<KakaoShareResult> {
    const result = await this.bridge.call(MODULE, 'shareList', payload as unknown as Record<string, unknown>);
    return result as unknown as KakaoShareResult;
  }

  async shareCustom(payload: ShareCustomPayload): Promise<KakaoShareResult> {
    const result = await this.bridge.call(MODULE, 'shareCustom', payload as unknown as Record<string, unknown>);
    return result as unknown as KakaoShareResult;
  }

  async isAvailable(): Promise<KakaoShareAvailability> {
    const result = await this.bridge.call(MODULE, 'isAvailable');
    return result as unknown as KakaoShareAvailability;
  }
}
