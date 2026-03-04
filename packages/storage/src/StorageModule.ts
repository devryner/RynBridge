import type { RynBridge } from '@rynbridge/core';
import type {
  StorageGetResponse,
  StorageKeysResponse,
  ReadFilePayload,
  ReadFileResponse,
  WriteFilePayload,
  WriteFileResponse,
  DeleteFilePayload,
  DeleteFileResponse,
  ListDirPayload,
  ListDirResponse,
  GetFileInfoPayload,
  FileInfo,
} from './types.js';

const MODULE = 'storage';

export class StorageModule {
  private readonly bridge: RynBridge;

  constructor(bridge: RynBridge) {
    this.bridge = bridge;
  }

  async get(key: string): Promise<string | null> {
    const result = await this.bridge.call(MODULE, 'get', { key });
    return (result as unknown as StorageGetResponse).value;
  }

  async set(key: string, value: string): Promise<void> {
    await this.bridge.call(MODULE, 'set', { key, value });
  }

  async remove(key: string): Promise<void> {
    await this.bridge.call(MODULE, 'remove', { key });
  }

  async clear(): Promise<void> {
    await this.bridge.call(MODULE, 'clear');
  }

  async keys(): Promise<string[]> {
    const result = await this.bridge.call(MODULE, 'keys');
    return (result as unknown as StorageKeysResponse).keys;
  }

  async readFile(payload: ReadFilePayload): Promise<string> {
    const result = await this.bridge.call(MODULE, 'readFile', payload as unknown as Record<string, unknown>);
    return (result as unknown as ReadFileResponse).content;
  }

  async writeFile(payload: WriteFilePayload): Promise<boolean> {
    const result = await this.bridge.call(MODULE, 'writeFile', payload as unknown as Record<string, unknown>);
    return (result as unknown as WriteFileResponse).success;
  }

  async deleteFile(payload: DeleteFilePayload): Promise<boolean> {
    const result = await this.bridge.call(MODULE, 'deleteFile', payload as unknown as Record<string, unknown>);
    return (result as unknown as DeleteFileResponse).success;
  }

  async listDir(payload: ListDirPayload): Promise<string[]> {
    const result = await this.bridge.call(MODULE, 'listDir', payload as unknown as Record<string, unknown>);
    return (result as unknown as ListDirResponse).files;
  }

  async getFileInfo(payload: GetFileInfoPayload): Promise<FileInfo> {
    const result = await this.bridge.call(MODULE, 'getFileInfo', payload as unknown as Record<string, unknown>);
    return result as unknown as FileInfo;
  }
}
