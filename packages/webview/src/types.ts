export interface OpenPayload {
  url: string;
  title?: string;
  style?: 'modal' | 'push' | 'fullScreen';
  allowedOrigins?: string[];
}

export interface OpenResult {
  webviewId: string;
}

export interface ClosePayload {
  webviewId: string;
}

export interface SendMessagePayload {
  targetId: string;
  data: Record<string, unknown>;
}

export interface PostEventPayload {
  targetId: string;
  event: string;
  data?: Record<string, unknown>;
}

export interface MessageEvent {
  sourceId: string;
  data: Record<string, unknown>;
}

export interface CloseEvent {
  webviewId: string;
  result?: Record<string, unknown>;
}

export interface WebViewInfo {
  webviewId: string;
  url: string;
  title?: string;
}

export interface GetWebViewsResult {
  webviews: WebViewInfo[];
}

export interface SetResultPayload {
  data: Record<string, unknown>;
}
