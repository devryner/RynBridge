import { RynBridge } from '@rynbridge/core';
import type {
  StartRecognitionPayload,
  StartRecognitionResult,
  StopRecognitionPayload,
  StopRecognitionResult,
  RecognitionResultEvent,
  SpeakPayload,
  GetVoicesResult,
  PermissionResult,
  PermissionStatus,
} from './types.js';

const MODULE = 'speech';

export class SpeechModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async startRecognition(payload?: StartRecognitionPayload): Promise<StartRecognitionResult> {
    const result = await this.bridge.call(MODULE, 'startRecognition', (payload ?? {}) as Record<string, unknown>);
    return result as unknown as StartRecognitionResult;
  }

  async stopRecognition(payload: StopRecognitionPayload): Promise<StopRecognitionResult> {
    const result = await this.bridge.call(MODULE, 'stopRecognition', payload as unknown as Record<string, unknown>);
    return result as unknown as StopRecognitionResult;
  }

  onRecognitionResult(listener: (data: RecognitionResultEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as RecognitionResultEvent);
    this.bridge.onEvent('speech:recognitionResult', wrapper);
    return () => this.bridge.offEvent('speech:recognitionResult', wrapper);
  }

  async speak(payload: SpeakPayload): Promise<void> {
    await this.bridge.call(MODULE, 'speak', payload as unknown as Record<string, unknown>);
  }

  stopSpeaking(): void {
    this.bridge.send(MODULE, 'stopSpeaking', {});
  }

  async getVoices(): Promise<GetVoicesResult> {
    const result = await this.bridge.call(MODULE, 'getVoices');
    return result as unknown as GetVoicesResult;
  }

  async requestPermission(): Promise<PermissionResult> {
    const result = await this.bridge.call(MODULE, 'requestPermission');
    return result as unknown as PermissionResult;
  }

  async getPermissionStatus(): Promise<PermissionStatus> {
    const result = await this.bridge.call(MODULE, 'getPermissionStatus');
    return result as unknown as PermissionStatus;
  }
}
