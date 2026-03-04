import { Command } from 'commander';
import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import pc from 'picocolors';

interface Check {
  name: string;
  check: () => string | null;
}

export const doctorCommand = new Command('doctor')
  .description('Check your development environment')
  .action(() => {
    console.log(pc.bold('\n🩺 RynBridge Doctor\n'));

    const checks: Check[] = [
      {
        name: 'Node.js',
        check: () => {
          try {
            const version = execSync('node --version', { encoding: 'utf-8' }).trim();
            const major = parseInt(version.replace('v', ''), 10);
            if (major < 20) return `${version} (requires >= 20)`;
            return null;
          } catch {
            return 'not found';
          }
        },
      },
      {
        name: 'pnpm',
        check: () => {
          try {
            execSync('pnpm --version', { encoding: 'utf-8' });
            return null;
          } catch {
            return 'not found (install: npm i -g pnpm)';
          }
        },
      },
      {
        name: 'contracts/',
        check: () => {
          const dir = join(process.cwd(), 'contracts');
          return existsSync(dir) ? null : 'directory not found';
        },
      },
      {
        name: 'Swift toolchain',
        check: () => {
          try {
            execSync('swift --version', { encoding: 'utf-8' });
            return null;
          } catch {
            return 'not found (optional, for iOS development)';
          }
        },
      },
      {
        name: 'Kotlin toolchain',
        check: () => {
          try {
            execSync('kotlinc -version 2>&1', { encoding: 'utf-8' });
            return null;
          } catch {
            return 'not found (optional, for Android development)';
          }
        },
      },
    ];

    let allPassed = true;
    for (const { name, check } of checks) {
      const result = check();
      if (result === null) {
        console.log(`  ${pc.green('✓')} ${name}`);
      } else {
        console.log(`  ${pc.yellow('⚠')} ${name} — ${pc.dim(result)}`);
        allPassed = false;
      }
    }

    console.log(
      allPassed
        ? pc.green('\n✓ All checks passed!\n')
        : pc.yellow('\n⚠ Some checks failed. See above for details.\n'),
    );
  });
