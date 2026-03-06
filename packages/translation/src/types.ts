export interface TranslatePayload {
  text: string;
  source: string;
  target: string;
}

export interface TranslateResult {
  text: string;
}

export interface TranslateBatchPayload {
  texts: string[];
  source: string;
  target: string;
}

export interface TranslateBatchResult {
  results: string[];
}

export interface DetectLanguagePayload {
  text: string;
}

export interface DetectLanguageResult {
  language: string;
  confidence: number;
}

export interface GetSupportedLanguagesResult {
  languages: string[];
}

export interface DownloadModelPayload {
  language: string;
}

export interface DownloadModelResult {
  success: boolean;
}

export interface DeleteModelPayload {
  language: string;
}

export interface DeleteModelResult {
  success: boolean;
}

export interface GetDownloadedModelsResult {
  models: string[];
}

export interface DownloadProgressEvent {
  language: string;
  progress: number;
}
