export interface StorageGetPayload {
  key: string;
}

export interface StorageGetResponse {
  value: string | null;
}

export interface StorageSetPayload {
  key: string;
  value: string;
}

export interface StorageRemovePayload {
  key: string;
}

export interface StorageKeysResponse {
  keys: string[];
}

export interface ReadFilePayload {
  path: string;
  encoding?: 'utf8' | 'base64';
}

export interface ReadFileResponse {
  content: string;
}

export interface WriteFilePayload {
  path: string;
  content: string;
  encoding?: 'utf8' | 'base64';
}

export interface WriteFileResponse {
  success: boolean;
}

export interface DeleteFilePayload {
  path: string;
}

export interface DeleteFileResponse {
  success: boolean;
}

export interface ListDirPayload {
  path: string;
}

export interface ListDirResponse {
  files: string[];
}

export interface GetFileInfoPayload {
  path: string;
}

export interface FileInfo {
  size: number;
  modifiedAt: string;
  isDirectory: boolean;
}
