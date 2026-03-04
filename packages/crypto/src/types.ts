export interface KeyPairResult {
  publicKey: string;
}

export interface KeyExchangePayload {
  remotePublicKey: string;
}

export interface KeyExchangeResult {
  sessionEstablished: boolean;
}

export interface EncryptPayload {
  data: string;
  associatedData?: string;
}

export interface EncryptResult {
  ciphertext: string;
  iv: string;
  tag: string;
}

export interface DecryptPayload {
  ciphertext: string;
  iv: string;
  tag: string;
  associatedData?: string;
}

export interface DecryptResult {
  plaintext: string;
}

export interface CryptoStatus {
  initialized: boolean;
  keyCreatedAt: string | null;
  algorithm: string;
}
