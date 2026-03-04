import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, basename } from 'node:path';
import type { Schema, ActionSchema, ModuleSchemaMap } from './types.js';

export function loadSchemas(contractsDir: string): ModuleSchemaMap {
  if (!existsSync(contractsDir)) {
    throw new Error(`Contracts directory not found: ${contractsDir}`);
  }

  const result: ModuleSchemaMap = {};

  const entries = readdirSync(contractsDir);
  for (const entry of entries) {
    const modulePath = join(contractsDir, entry);
    if (!statSync(modulePath).isDirectory()) continue;
    if (entry === 'core') continue;

    const actions = loadModuleSchemas(modulePath);
    if (actions.length > 0) {
      result[entry] = actions;
    }
  }

  return result;
}

function loadModuleSchemas(modulePath: string): ActionSchema[] {
  const files = readdirSync(modulePath).filter((f) => f.endsWith('.schema.json'));

  const actionMap = new Map<string, { request?: Schema; response?: Schema }>();

  for (const file of files) {
    const name = basename(file, '.schema.json');
    const match = name.match(/^(.+)\.(request|response)$/);
    if (!match) continue;

    const [, action, kind] = match;
    const schema = JSON.parse(readFileSync(join(modulePath, file), 'utf-8')) as Schema;

    if (!actionMap.has(action)) {
      actionMap.set(action, {});
    }
    const entry = actionMap.get(action)!;
    if (kind === 'request') {
      entry.request = schema;
    } else {
      entry.response = schema;
    }
  }

  const actions: ActionSchema[] = [];
  for (const [action, schemas] of actionMap) {
    if (!schemas.request) continue;
    actions.push({
      action,
      request: schemas.request,
      response: schemas.response,
    });
  }

  return actions.sort((a, b) => a.action.localeCompare(b.action));
}
