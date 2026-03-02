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
