import { RynBridge } from '@rynbridge/core';
import type {
  TranslatePayload,
  TranslateResult,
  TranslateBatchPayload,
  TranslateBatchResult,
  DetectLanguagePayload,
  DetectLanguageResult,
  GetSupportedLanguagesResult,
  DownloadModelPayload,
  DownloadModelResult,
  DeleteModelPayload,
  DeleteModelResult,
  GetDownloadedModelsResult,
  DownloadProgressEvent,
} from './types.js';

const MODULE = 'translation';

export class TranslationModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async translate(payload: TranslatePayload): Promise<TranslateResult> {
    const result = await this.bridge.call(MODULE, 'translate', payload as unknown as Record<string, unknown>);
    return result as unknown as TranslateResult;
  }

  async translateBatch(payload: TranslateBatchPayload): Promise<TranslateBatchResult> {
    const result = await this.bridge.call(MODULE, 'translateBatch', payload as unknown as Record<string, unknown>);
    return result as unknown as TranslateBatchResult;
  }

  async detectLanguage(payload: DetectLanguagePayload): Promise<DetectLanguageResult> {
    const result = await this.bridge.call(MODULE, 'detectLanguage', payload as unknown as Record<string, unknown>);
    return result as unknown as DetectLanguageResult;
  }

  async getSupportedLanguages(): Promise<GetSupportedLanguagesResult> {
    const result = await this.bridge.call(MODULE, 'getSupportedLanguages');
    return result as unknown as GetSupportedLanguagesResult;
  }

  async downloadModel(payload: DownloadModelPayload): Promise<DownloadModelResult> {
    const result = await this.bridge.call(MODULE, 'downloadModel', payload as unknown as Record<string, unknown>);
    return result as unknown as DownloadModelResult;
  }

  async deleteModel(payload: DeleteModelPayload): Promise<DeleteModelResult> {
    const result = await this.bridge.call(MODULE, 'deleteModel', payload as unknown as Record<string, unknown>);
    return result as unknown as DeleteModelResult;
  }

  async getDownloadedModels(): Promise<GetDownloadedModelsResult> {
    const result = await this.bridge.call(MODULE, 'getDownloadedModels');
    return result as unknown as GetDownloadedModelsResult;
  }

  onDownloadProgress(listener: (data: DownloadProgressEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as DownloadProgressEvent);
    this.bridge.onEvent('translation:downloadProgress', wrapper);
    return () => this.bridge.offEvent('translation:downloadProgress', wrapper);
  }
}
