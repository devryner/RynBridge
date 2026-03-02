export interface SecureStorageGetPayload {
  key: string;
}

export interface SecureStorageGetResponse {
  value: string | null;
}

export interface SecureStorageSetPayload {
  key: string;
  value: string;
}

export interface SecureStorageRemovePayload {
  key: string;
}

export interface SecureStorageHasPayload {
  key: string;
}

export interface SecureStorageHasResponse {
  exists: boolean;
}
