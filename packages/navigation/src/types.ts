export interface PushPayload {
  screen: string;
  params?: Record<string, unknown>;
}

export interface PopResult {
  success: boolean;
}

export interface PresentPayload {
  screen: string;
  style?: 'modal' | 'fullScreen' | 'pageSheet';
  params?: Record<string, unknown>;
}

export interface OpenURLPayload {
  url: string;
}

export interface OpenURLResult {
  success: boolean;
}

export interface CanOpenURLPayload {
  url: string;
}

export interface CanOpenURLResult {
  canOpen: boolean;
}

export interface InitialURLResult {
  url: string | null;
}

export interface DeepLinkEvent {
  url: string;
}

export interface AppState {
  state: 'active' | 'inactive' | 'background';
}

export interface AppStateChangeEvent {
  state: 'active' | 'inactive' | 'background';
}
