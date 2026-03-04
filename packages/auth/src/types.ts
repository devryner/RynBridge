export interface AuthUser {
  id: string;
  email: string | null;
  name: string | null;
  profileImage: string | null;
}

export interface LoginPayload {
  provider: string;
  scopes?: string[];
}

export interface LoginResult {
  token: string;
  refreshToken: string | null;
  expiresAt: string;
  user: AuthUser | null;
}

export interface TokenResult {
  token: string | null;
  expiresAt: string | null;
}

export interface UserResult {
  user: AuthUser | null;
}

export interface AuthStateEvent {
  authenticated: boolean;
  user: AuthUser | null;
}
