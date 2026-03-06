import { describe, it, expect, beforeEach } from 'vitest';
import { RynBridge, MockTransport } from '@rynbridge/core';
import type { BridgeResponse } from '@rynbridge/core';
import { SpeechModule } from '../SpeechModule.js';

describe('SpeechModule', () => {
  let transport: MockTransport;
  let bridge: RynBridge;
  let speech: SpeechModule;

  beforeEach(() => {
    transport = new MockTransport();
    bridge = new RynBridge({ timeout: 5000 }, transport);
    speech = new SpeechModule(bridge);
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

  describe('startRecognition', () => {
    it('sends correct module and action without payload', async () => {
      const promise = speech.startRecognition();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('speech');
      expect(sent.action).toBe('startRecognition');
      expect(sent.payload).toEqual({});

      respondSuccess({ sessionId: 'session-123' });

      const result = await promise;
      expect(result).toEqual({ sessionId: 'session-123' });
    });

    it('sends language option', async () => {
      const promise = speech.startRecognition({ language: 'ko-KR' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({ language: 'ko-KR' });

      respondSuccess({ sessionId: 'session-456' });

      const result = await promise;
      expect(result).toEqual({ sessionId: 'session-456' });
    });
  });

  describe('stopRecognition', () => {
    it('sends sessionId and returns transcript', async () => {
      const promise = speech.stopRecognition({ sessionId: 'session-123' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('speech');
      expect(sent.action).toBe('stopRecognition');
      expect(sent.payload).toEqual({ sessionId: 'session-123' });

      respondSuccess({ transcript: 'Hello world' });

      const result = await promise;
      expect(result).toEqual({ transcript: 'Hello world' });
    });
  });

  describe('onRecognitionResult', () => {
    it('subscribes to recognition result events and returns unsubscribe function', () => {
      const received: unknown[] = [];
      const unsubscribe = speech.onRecognitionResult((data) => {
        received.push(data);
      });

      simulateNativeEvent('speech', 'recognitionResult', { transcript: 'Hello', isFinal: false });

      expect(received).toHaveLength(1);
      expect(received[0]).toEqual({ transcript: 'Hello', isFinal: false });

      simulateNativeEvent('speech', 'recognitionResult', { transcript: 'Hello world', isFinal: true });

      expect(received).toHaveLength(2);
      expect(received[1]).toEqual({ transcript: 'Hello world', isFinal: true });

      unsubscribe();
      simulateNativeEvent('speech', 'recognitionResult', { transcript: 'After unsubscribe', isFinal: false });

      expect(received).toHaveLength(2);
    });
  });

  describe('speak', () => {
    it('sends text to speak', async () => {
      const promise = speech.speak({ text: 'Hello world' });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('speech');
      expect(sent.action).toBe('speak');
      expect(sent.payload).toEqual({ text: 'Hello world' });

      respondSuccess();

      await promise;
    });

    it('sends all options', async () => {
      const promise = speech.speak({
        text: 'Test',
        language: 'en-US',
        rate: 1.5,
        pitch: 0.8,
        voiceId: 'voice-1',
      });

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.payload).toEqual({
        text: 'Test',
        language: 'en-US',
        rate: 1.5,
        pitch: 0.8,
        voiceId: 'voice-1',
      });

      respondSuccess();

      await promise;
    });
  });

  describe('stopSpeaking', () => {
    it('sends fire-and-forget', () => {
      speech.stopSpeaking();

      expect(transport.sent).toHaveLength(1);
      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('speech');
      expect(sent.action).toBe('stopSpeaking');
      expect(sent.payload).toEqual({});
    });
  });

  describe('getVoices', () => {
    it('returns available voices', async () => {
      const promise = speech.getVoices();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('speech');
      expect(sent.action).toBe('getVoices');

      respondSuccess({
        voices: [
          { id: 'voice-1', name: 'Siri Female', language: 'en-US' },
          { id: 'voice-2', name: 'Siri Male', language: 'ko-KR' },
        ],
      });

      const result = await promise;
      expect(result).toEqual({
        voices: [
          { id: 'voice-1', name: 'Siri Female', language: 'en-US' },
          { id: 'voice-2', name: 'Siri Male', language: 'ko-KR' },
        ],
      });
    });
  });

  describe('requestPermission', () => {
    it('returns permission result', async () => {
      const promise = speech.requestPermission();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('speech');
      expect(sent.action).toBe('requestPermission');

      respondSuccess({ granted: true });

      const result = await promise;
      expect(result).toEqual({ granted: true });
    });
  });

  describe('getPermissionStatus', () => {
    it('returns permission status', async () => {
      const promise = speech.getPermissionStatus();

      const sent = JSON.parse(transport.sent[0]);
      expect(sent.module).toBe('speech');
      expect(sent.action).toBe('getPermissionStatus');

      respondSuccess({ status: 'granted' });

      const result = await promise;
      expect(result).toEqual({ status: 'granted' });
    });
  });

  describe('error handling', () => {
    it('propagates bridge errors', async () => {
      const promise = speech.startRecognition();

      const sent = JSON.parse(transport.sent[0]);
      const response: BridgeResponse = {
        id: sent.id,
        status: 'error',
        payload: {},
        error: { code: 'UNKNOWN', message: 'Speech recognition unavailable' },
      };
      transport.simulateIncoming(JSON.stringify(response));

      await expect(promise).rejects.toThrow('Speech recognition unavailable');
    });
  });
});
