import type { BridgeModule, ActionHandler } from '../types.js';
import { ErrorCode, RynBridgeError } from '../errors.js';

export class ModuleRegistry {
  private readonly modules = new Map<string, BridgeModule>();

  register(module: BridgeModule): void {
    this.modules.set(module.name, module);
  }

  unregister(name: string): boolean {
    return this.modules.delete(name);
  }

  getAction(moduleName: string, actionName: string): ActionHandler {
    const mod = this.modules.get(moduleName);
    if (!mod) {
      throw new RynBridgeError(
        ErrorCode.MODULE_NOT_FOUND,
        `Module "${moduleName}" is not registered`,
        { module: moduleName },
      );
    }

    const handler = mod.actions[actionName];
    if (!handler) {
      throw new RynBridgeError(
        ErrorCode.ACTION_NOT_FOUND,
        `Action "${actionName}" not found in module "${moduleName}"`,
        { module: moduleName, action: actionName },
      );
    }

    return handler;
  }

  has(name: string): boolean {
    return this.modules.has(name);
  }

  getModule(name: string): BridgeModule | undefined {
    return this.modules.get(name);
  }

  get moduleNames(): string[] {
    return [...this.modules.keys()];
  }
}
