import type {
  BridgeConfig,
  BridgeModule,
  BridgeResponse,
  ActionHandler,
  Transport,
} from './types.js';
import { DEFAULT_CONFIG } from './types.js';
import { ErrorCode, RynBridgeError } from './errors.js';
import { MessageSerializer } from './message/MessageSerializer.js';
import { MessageDeserializer } from './message/MessageDeserializer.js';
import { CallbackRegistry } from './callback/CallbackRegistry.js';
import { EventEmitter } from './event/EventEmitter.js';
import { ModuleRegistry } from './module/ModuleRegistry.js';
import { WebViewTransport } from './transport/WebViewTransport.js';

export class RynBridge {
  private readonly config: Required<BridgeConfig>;
  private readonly transport: Transport;
  private readonly serializer: MessageSerializer;
  private readonly deserializer: MessageDeserializer;
  private readonly callbacks: CallbackRegistry;
  private readonly events: EventEmitter;
  private readonly modules: ModuleRegistry;
  private readonly actionHandlers = new Map<string, ActionHandler>();
  private disposed = false;

  constructor(config?: BridgeConfig, transport?: Transport) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.transport = transport ?? new WebViewTransport();
    this.serializer = new MessageSerializer(this.config.version);
    this.deserializer = new MessageDeserializer();
    this.callbacks = new CallbackRegistry();
    this.events = new EventEmitter();
    this.modules = new ModuleRegistry();

    this.transport.onMessage((raw) => this.handleIncomingMessage(raw));
  }

  register(module: BridgeModule): void {
    this.modules.register(module);
  }

  async call(
    module: string,
    action: string,
    payload: Record<string, unknown> = {},
  ): Promise<Record<string, unknown>> {
    this.assertNotDisposed();

    const request = this.serializer.createRequest(module, action, payload);
    const responsePromise = this.callbacks.register(request.id, this.config.timeout);
    const message = this.serializer.serialize(request);

    this.transport.send(message);

    const response = await responsePromise;

    if (response.status === 'error') {
      throw new RynBridgeError(
        (response.error?.code as RynBridgeError['code']) ?? ErrorCode.UNKNOWN,
        response.error?.message ?? 'Unknown error from native',
        response.error?.details ?? {},
      );
    }

    return response.payload;
  }

  send(
    module: string,
    action: string,
    payload: Record<string, unknown> = {},
  ): void {
    this.assertNotDisposed();

    const request = this.serializer.createRequest(module, action, payload);
    const message = this.serializer.serialize(request);
    this.transport.send(message);
  }

  on(action: string, handler: ActionHandler): void {
    this.actionHandlers.set(action, handler);
  }

  off(action: string): void {
    this.actionHandlers.delete(action);
  }

  onEvent(event: string, listener: (data: Record<string, unknown>) => void): void {
    this.events.on(event, listener);
  }

  offEvent(event: string, listener: (data: Record<string, unknown>) => void): void {
    this.events.off(event, listener);
  }

  dispose(): void {
    this.disposed = true;
    this.callbacks.clear();
    this.events.removeAllListeners();
    this.actionHandlers.clear();
    this.transport.dispose();
  }

  private handleIncomingMessage(raw: string): void {
    try {
      const incoming = this.deserializer.deserialize(raw);

      if (incoming.type === 'response') {
        this.handleResponse(incoming.data);
      } else {
        this.handleIncomingRequest(incoming.data);
      }
    } catch (error) {
      if (error instanceof RynBridgeError) {
        this.events.emit('error', error.toJSON());
      }
    }
  }

  private handleResponse(response: BridgeResponse): void {
    this.callbacks.resolve(response.id, response);
  }

  private async handleIncomingRequest(request: {
    id: string;
    module: string;
    action: string;
    payload: Record<string, unknown>;
    version: string;
  }): Promise<void> {
    // Check action handlers first (registered via on())
    const directHandler = this.actionHandlers.get(request.action);

    // Then check module registry
    let handler: ActionHandler | undefined = directHandler;
    if (!handler) {
      try {
        handler = this.modules.getAction(request.module, request.action);
      } catch {
        // If it's a fire-and-forget event, emit it
        this.events.emit(`${request.module}:${request.action}`, request.payload);
        return;
      }
    }

    try {
      const result = await handler(request.payload);
      const response: BridgeResponse = {
        id: request.id,
        status: 'success',
        payload: result,
        error: null,
      };
      this.transport.send(JSON.stringify(response));
    } catch (error) {
      const bridgeError =
        error instanceof RynBridgeError
          ? error
          : new RynBridgeError(ErrorCode.UNKNOWN, String(error));
      const response: BridgeResponse = {
        id: request.id,
        status: 'error',
        payload: {},
        error: bridgeError.toJSON(),
      };
      this.transport.send(JSON.stringify(response));
    }
  }

  private assertNotDisposed(): void {
    if (this.disposed) {
      throw new RynBridgeError(
        ErrorCode.TRANSPORT_ERROR,
        'Bridge has been disposed',
      );
    }
  }
}
