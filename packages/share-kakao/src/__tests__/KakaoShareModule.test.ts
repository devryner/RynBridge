import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { KakaoShareModule } from '../KakaoShareModule.js';

describe('KakaoShareModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let kakaoShare: KakaoShareModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    kakaoShare = new KakaoShareModule(bridge);
  });

  function respondSuccess(payload: Record<string, unknown> = {}) {
    const sent = JSON.parse(transport.sent[transport.sent.length - 1]);
    const response: BridgeResponse = {
      id: sent.id,
      status: 'success',
      payload,
      error: null,
    };
    transport.simulateIncoming(JSON.stringify(response));
  }

  describe('shareFeed', () => {
    it('sends feed template payload', async () => {
      const payload = {
        content: {
          title: 'Test Title',
          imageUrl: 'https://example.com/image.png',
          link: { webUrl: 'https://example.com' },
        },
        buttons: [{ title: 'Open', link: { webUrl: 'https://example.com' } }],
      };

      const promise = kakaoShare.shareFeed(payload);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('kakaoShare');
      expect(sent.action).toBe('shareFeed');
      expect(sent.payload.content.title).toBe('Test Title');
      expect(sent.payload.buttons).toHaveLength(1);

      respondSuccess({ success: true, sharingUrl: 'https://kakao.com/share/123' });
      const result = await promise;
      expect(result.success).toBe(true);
      expect(result.sharingUrl).toBe('https://kakao.com/share/123');
    });

    it('sends feed template with social and serverCallbackArgs', async () => {
      const payload = {
        content: {
          title: 'Social Post',
          imageUrl: 'https://example.com/img.png',
          link: { mobileWebUrl: 'https://m.example.com' },
        },
        social: { likeCount: 10, commentCount: 5 },
        serverCallbackArgs: { key: 'value' },
      };

      const promise = kakaoShare.shareFeed(payload);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload.social.likeCount).toBe(10);
      expect(sent.payload.serverCallbackArgs.key).toBe('value');

      respondSuccess({ success: true });
      await promise;
    });
  });

  describe('shareCommerce', () => {
    it('sends commerce template payload', async () => {
      const payload = {
        content: {
          title: 'Product',
          imageUrl: 'https://example.com/product.png',
          link: { webUrl: 'https://example.com/product' },
        },
        commerce: { regularPrice: 10000, discountPrice: 8000 },
      };

      const promise = kakaoShare.shareCommerce(payload);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('kakaoShare');
      expect(sent.action).toBe('shareCommerce');
      expect(sent.payload.commerce.regularPrice).toBe(10000);

      respondSuccess({ success: true });
      const result = await promise;
      expect(result.success).toBe(true);
    });
  });

  describe('shareList', () => {
    it('sends list template payload', async () => {
      const payload = {
        headerTitle: 'Top Items',
        headerLink: { webUrl: 'https://example.com/list' },
        contents: [
          {
            title: 'Item 1',
            imageUrl: 'https://example.com/1.png',
            link: { webUrl: 'https://example.com/1' },
          },
          {
            title: 'Item 2',
            imageUrl: 'https://example.com/2.png',
            link: { webUrl: 'https://example.com/2' },
          },
        ],
      };

      const promise = kakaoShare.shareList(payload);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('kakaoShare');
      expect(sent.action).toBe('shareList');
      expect(sent.payload.contents).toHaveLength(2);

      respondSuccess({ success: true });
      const result = await promise;
      expect(result.success).toBe(true);
    });
  });

  describe('shareCustom', () => {
    it('sends custom template payload', async () => {
      const promise = kakaoShare.shareCustom({
        templateId: 12345,
        templateArgs: { userName: 'Alice', gameId: '99' },
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('kakaoShare');
      expect(sent.action).toBe('shareCustom');
      expect(sent.payload.templateId).toBe(12345);
      expect(sent.payload.templateArgs.userName).toBe('Alice');

      respondSuccess({ success: true });
      const result = await promise;
      expect(result.success).toBe(true);
    });
  });

  describe('isAvailable', () => {
    it('checks KakaoTalk availability', async () => {
      const promise = kakaoShare.isAvailable();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('kakaoShare');
      expect(sent.action).toBe('isAvailable');

      respondSuccess({ available: true });
      const result = await promise;
      expect(result.available).toBe(true);
    });

    it('returns false when KakaoTalk not installed', async () => {
      const promise = kakaoShare.isAvailable();
      respondSuccess({ available: false });
      const result = await promise;
      expect(result.available).toBe(false);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = kakaoShare.shareFeed({
        content: {
          title: 'Test',
          imageUrl: 'https://example.com/img.png',
          link: { webUrl: 'https://example.com' },
        },
      });

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Kakao share failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Kakao share failed');
    });
  });
});
