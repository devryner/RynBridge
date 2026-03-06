export interface SharePayload {
  text?: string;
  url?: string;
  title?: string;
}

export interface ShareFilePayload {
  filePath: string;
  mimeType: string;
}

export interface ShareResult {
  success: boolean;
}

export interface ClipboardText {
  text: string;
}

export interface CanShareResult {
  canShare: boolean;
}
