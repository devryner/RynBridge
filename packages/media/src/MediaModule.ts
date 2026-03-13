import { RynBridge } from '@rynbridge/core';
import type {
  PlayAudioPayload,
  PlayAudioResult,
  PlayerPayload,
  AudioStatus,
  StartRecordingPayload,
  StartRecordingResult,
  StopRecordingPayload,
  StopRecordingResult,
  PickMediaPayload,
  PickMediaResult,
  PlaybackCompleteEvent,
} from './types.js';

const MODULE = 'media';

export class MediaModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async playAudio(payload: PlayAudioPayload): Promise<PlayAudioResult> {
    const result = await this.bridge.call(MODULE, 'playAudio', payload as unknown as Record<string, unknown>);
    return result as unknown as PlayAudioResult;
  }

  async pauseAudio(payload: PlayerPayload): Promise<void> {
    await this.bridge.call(MODULE, 'pauseAudio', payload as unknown as Record<string, unknown>);
  }

  async stopAudio(payload: PlayerPayload): Promise<void> {
    await this.bridge.call(MODULE, 'stopAudio', payload as unknown as Record<string, unknown>);
  }

  async getAudioStatus(payload: PlayerPayload): Promise<AudioStatus> {
    const result = await this.bridge.call(MODULE, 'getAudioStatus', payload as unknown as Record<string, unknown>);
    return result as unknown as AudioStatus;
  }

  async startRecording(payload?: StartRecordingPayload): Promise<StartRecordingResult> {
    const result = await this.bridge.call(MODULE, 'startRecording', (payload ?? {}) as Record<string, unknown>);
    return result as unknown as StartRecordingResult;
  }

  async stopRecording(payload: StopRecordingPayload): Promise<StopRecordingResult> {
    const result = await this.bridge.call(MODULE, 'stopRecording', payload as unknown as Record<string, unknown>);
    return result as unknown as StopRecordingResult;
  }

  async pickMedia(payload?: PickMediaPayload): Promise<PickMediaResult> {
    const result = await this.bridge.call(MODULE, 'pickMedia', (payload ?? {}) as Record<string, unknown>);
    return result as unknown as PickMediaResult;
  }

  onPlaybackComplete(listener: (data: PlaybackCompleteEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as PlaybackCompleteEvent);
    this.bridge.onEvent('media:playbackComplete', wrapper);
    return () => this.bridge.offEvent('media:playbackComplete', wrapper);
  }
}
