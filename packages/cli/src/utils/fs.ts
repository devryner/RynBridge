import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { dirname } from 'node:path';
import pc from 'picocolors';

export function writeFile(path: string, content: string): void {
  const dir = dirname(path);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  writeFileSync(path, content, 'utf-8');
  console.log(`  ${pc.green('✓')} ${path}`);
}
