interface Window {
  webkit?: {
    messageHandlers?: {
      RynBridge?: { postMessage(message: string): void };
    };
  };
  RynBridgeAndroid?: {
    postMessage(message: string): void;
  };
  __rynbridge_receive?: (message: string) => void;
}
