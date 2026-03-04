import { existsSync } from 'node:fs';
import { join } from 'node:path';

export type PackageManager = 'pnpm' | 'yarn' | 'npm';

export function detectPackageManager(cwd: string = process.cwd()): PackageManager {
  if (existsSync(join(cwd, 'pnpm-lock.yaml'))) return 'pnpm';
  if (existsSync(join(cwd, 'yarn.lock'))) return 'yarn';
  return 'npm';
}

export function installCmd(pm: PackageManager, pkg: string): string {
  switch (pm) {
    case 'pnpm':
      return `pnpm add ${pkg}`;
    case 'yarn':
      return `yarn add ${pkg}`;
    case 'npm':
      return `npm install ${pkg}`;
  }
}
