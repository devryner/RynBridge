export interface StartRecognitionPayload {
  language?: string;
}

export interface StartRecognitionResult {
  sessionId: string;
}

export interface StopRecognitionPayload {
  sessionId: string;
}

export interface StopRecognitionResult {
  transcript: string;
}

export interface RecognitionResultEvent {
  transcript: string;
  isFinal: boolean;
}

export interface SpeakPayload {
  text: string;
  language?: string;
  rate?: number;
  pitch?: number;
  voiceId?: string;
}

export interface Voice {
  id: string;
  name: string;
  language: string;
}

export interface GetVoicesResult {
  voices: Voice[];
}

export interface PermissionResult {
  granted: boolean;
}

export interface PermissionStatus {
  status: string;
}
