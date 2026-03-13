import { RynBridge } from '@rynbridge/core';
import type {
  LoginPayload,
  LoginResult,
  TokenResult,
  UserResult,
  AuthStateEvent,
} from './types.js';

const MODULE = 'auth';

export class AuthModule {
  private readonly bridge: RynBridge;

  constructor(bridge?: RynBridge) {
    this.bridge = bridge ?? RynBridge.shared;
  }

  async login(payload: LoginPayload): Promise<LoginResult> {
    const result = await this.bridge.call(MODULE, 'login', payload as unknown as Record<string, unknown>);
    return result as unknown as LoginResult;
  }

  async logout(): Promise<void> {
    await this.bridge.call(MODULE, 'logout');
  }

  async getToken(): Promise<TokenResult> {
    const result = await this.bridge.call(MODULE, 'getToken');
    return result as unknown as TokenResult;
  }

  async refreshToken(): Promise<LoginResult> {
    const result = await this.bridge.call(MODULE, 'refreshToken');
    return result as unknown as LoginResult;
  }

  async getUser(): Promise<UserResult> {
    const result = await this.bridge.call(MODULE, 'getUser');
    return result as unknown as UserResult;
  }

  onAuthStateChange(listener: (data: AuthStateEvent) => void): () => void {
    const wrapper = (data: Record<string, unknown>) => listener(data as unknown as AuthStateEvent);
    this.bridge.onEvent('auth:authStateChange', wrapper);
    return () => this.bridge.offEvent('auth:authStateChange', wrapper);
  }
}
