export interface PlayAudioPayload {
  source: string;
  loop?: boolean;
  volume?: number;
}

export interface PlayAudioResult {
  playerId: string;
}

export interface PlayerPayload {
  playerId: string;
}

export interface AudioStatus {
  position: number;
  duration: number;
  isPlaying: boolean;
}

export interface StartRecordingPayload {
  format?: 'wav' | 'mp3' | 'm4a' | 'aac';
  quality?: 'low' | 'medium' | 'high';
}

export interface StartRecordingResult {
  recordingId: string;
}

export interface StopRecordingPayload {
  recordingId: string;
}

export interface StopRecordingResult {
  filePath: string;
  duration: number;
  size: number;
}

export interface PickMediaPayload {
  type?: 'image' | 'video' | 'any';
  multiple?: boolean;
}

export interface MediaFile {
  name: string;
  path: string;
  mimeType: string;
  size: number;
}

export interface PickMediaResult {
  files: MediaFile[];
}

export interface PlaybackCompleteEvent {
  playerId: string;
}
