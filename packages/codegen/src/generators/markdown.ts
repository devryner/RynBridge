import type { GeneratorOptions, Schema, SchemaProperty } from '../types.js';

export function generateMarkdown(options: GeneratorOptions): string {
  const lines: string[] = [
    `# ${capitalize(options.moduleName)} Module API`,
    '',
  ];

  for (const action of options.actions) {
    lines.push(`## ${options.moduleName}.${action.action}`);
    lines.push('');
    if (action.request.description) {
      lines.push(action.request.description);
      lines.push('');
    }

    lines.push('### Request');
    lines.push('');
    lines.push(schemaToTable(action.request));
    lines.push('');

    if (action.response) {
      lines.push('### Response');
      lines.push('');
      lines.push(schemaToTable(action.response));
      lines.push('');
    } else {
      lines.push('*Fire-and-forget — no response.*');
      lines.push('');
    }
  }

  return lines.join('\n');
}

function schemaToTable(schema: Schema): string {
  const entries = Object.entries(schema.properties);
  if (entries.length === 0) {
    return '*No parameters.*';
  }

  const required = new Set(schema.required ?? []);
  const lines: string[] = [];

  lines.push('| Field | Type | Required | Description |');
  lines.push('|-------|------|----------|-------------|');

  for (const [name, prop] of entries) {
    const typeStr = propToDisplayType(prop);
    const req = required.has(name) ? 'Yes' : 'No';
    const desc = prop.description ?? '';
    lines.push(`| \`${name}\` | \`${typeStr}\` | ${req} | ${desc} |`);
  }

  return lines.join('\n');
}

function propToDisplayType(prop: SchemaProperty): string {
  if (prop.enum) {
    return prop.enum.map((v) => `"${v}"`).join(' | ');
  }

  switch (prop.type) {
    case 'array':
      if (prop.items) {
        return `${prop.items.type}[]`;
      }
      return 'array';
    default:
      return prop.type;
  }
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
