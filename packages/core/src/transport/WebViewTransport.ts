import type { Transport } from '../types.js';

export class WebViewTransport implements Transport {
  private handler: ((message: string) => void) | null = null;

  constructor() {
    if (typeof window !== 'undefined') {
      window.__rynbridge_receive = (message: string) => {
        this.handler?.(message);
      };
    }
  }

  send(message: string): void {
    if (typeof window === 'undefined') return;

    // iOS: WKWebView
    if (window.webkit?.messageHandlers?.RynBridge) {
      window.webkit.messageHandlers.RynBridge.postMessage(message);
      return;
    }

    // Android: WebView.addJavascriptInterface
    if (window.RynBridgeAndroid) {
      window.RynBridgeAndroid.postMessage(message);
      return;
    }
  }

  onMessage(handler: (message: string) => void): void {
    this.handler = handler;
  }

  dispose(): void {
    this.handler = null;
    if (typeof window !== 'undefined') {
      window.__rynbridge_receive = undefined;
    }
  }
}
