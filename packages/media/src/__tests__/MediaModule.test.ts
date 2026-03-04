import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { MediaModule } from '../MediaModule.js';

describe('MediaModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let media: MediaModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    media = new MediaModule(bridge);
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

  function simulateNativeEvent(module: string, action: string, payload: Record<string, unknown>) {
    const event = JSON.stringify({
      id: 'event-' + Math.random().toString(36).slice(2),
      module,
      action,
      payload,
      version: '1.0.0',
    });
    transport.simulateIncoming(event);
  }

  describe('playAudio', () => {
    it('sends play audio request and returns player id', async () => {
      const promise = media.playAudio({ source: 'https://example.com/audio.mp3', loop: true, volume: 0.8 });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('media');
      expect(sent.action).toBe('playAudio');
      expect(sent.payload).toEqual({ source: 'https://example.com/audio.mp3', loop: true, volume: 0.8 });

      respondSuccess({ playerId: 'player-1' });
      const result = await promise;
      expect(result.playerId).toBe('player-1');
    });
  });

  describe('pauseAudio', () => {
    it('sends pause audio request', async () => {
      const promise = media.pauseAudio({ playerId: 'player-1' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('pauseAudio');
      expect(sent.payload).toEqual({ playerId: 'player-1' });
      respondSuccess();
      await promise;
    });
  });

  describe('stopAudio', () => {
    it('sends stop audio request', async () => {
      const promise = media.stopAudio({ playerId: 'player-1' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('stopAudio');
      respondSuccess();
      await promise;
    });
  });

  describe('getAudioStatus', () => {
    it('returns audio status', async () => {
      const promise = media.getAudioStatus({ playerId: 'player-1' });
      respondSuccess({ position: 30.5, duration: 120.0, isPlaying: true });
      const result = await promise;
      expect(result.position).toBe(30.5);
      expect(result.duration).toBe(120.0);
      expect(result.isPlaying).toBe(true);
    });
  });

  describe('startRecording', () => {
    it('starts recording with options', async () => {
      const promise = media.startRecording({ format: 'm4a', quality: 'high' });
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.action).toBe('startRecording');
      expect(sent.payload).toEqual({ format: 'm4a', quality: 'high' });
      respondSuccess({ recordingId: 'rec-1' });
      const result = await promise;
      expect(result.recordingId).toBe('rec-1');
    });

    it('starts recording without options', async () => {
      const promise = media.startRecording();
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({});
      respondSuccess({ recordingId: 'rec-2' });
      const result = await promise;
      expect(result.recordingId).toBe('rec-2');
    });
  });

  describe('stopRecording', () => {
    it('stops recording and returns file info', async () => {
      const promise = media.stopRecording({ recordingId: 'rec-1' });
      respondSuccess({ filePath: '/tmp/recording.m4a', duration: 65.3, size: 1048576 });
      const result = await promise;
      expect(result.filePath).toBe('/tmp/recording.m4a');
      expect(result.duration).toBe(65.3);
      expect(result.size).toBe(1048576);
    });
  });

  describe('pickMedia', () => {
    it('picks media files', async () => {
      const promise = media.pickMedia({ type: 'image', multiple: true });
      respondSuccess({
        files: [
          { name: 'photo.jpg', path: '/tmp/photo.jpg', mimeType: 'image/jpeg', size: 2048 },
        ],
      });
      const result = await promise;
      expect(result.files).toHaveLength(1);
      expect(result.files[0].name).toBe('photo.jpg');
    });
  });

  describe('onPlaybackComplete', () => {
    it('subscribes to playback complete events and returns unsubscribe', () => {
      const received: unknown[] = [];
      const unsub = media.onPlaybackComplete((data) => received.push(data));

      simulateNativeEvent('media', 'playbackComplete', { playerId: 'player-1' });
      expect(received).toHaveLength(1);
      expect((received[0] as any).playerId).toBe('player-1');

      unsub();
      simulateNativeEvent('media', 'playbackComplete', { playerId: 'player-2' });
      expect(received).toHaveLength(1);
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = media.playAudio({ source: 'invalid' });
      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Playback failed' },
      };
      transport.simulateIncoming(JSON.stringify(response));
      await expect(promise).rejects.toThrow('Playback failed');
    });
  });
});
