import { Command } from 'commander';
import { execSync } from 'node:child_process';
import pc from 'picocolors';
import { detectPackageManager, installCmd } from '../utils/detect-pm.js';

const KNOWN_MODULES = ['core', 'device', 'storage', 'secure-storage', 'ui'];

export const addCommand = new Command('add')
  .description('Add a RynBridge module to your project')
  .argument('<module>', 'Module name (e.g., device, storage, ui)')
  .action((moduleName: string) => {
    if (!KNOWN_MODULES.includes(moduleName)) {
      console.log(
        pc.yellow(`⚠ Unknown module "${moduleName}". Known modules: ${KNOWN_MODULES.join(', ')}`),
      );
    }

    const pm = detectPackageManager();
    const pkg = `@rynbridge/${moduleName}`;
    const cmd = installCmd(pm, pkg);

    console.log(pc.dim(`\nDetected package manager: ${pm}`));
    console.log(pc.dim(`Running: ${cmd}\n`));

    try {
      execSync(cmd, { stdio: 'inherit' });
      console.log(pc.green(`\n✓ Installed ${pkg}`));
    } catch {
      console.error(pc.red(`\n✗ Failed to install ${pkg}`));
      process.exit(1);
    }

    console.log(pc.dim(`\nUsage example:`));
    console.log(`  import { ${moduleClassName(moduleName)} } from '${pkg}';`);
    console.log(`  const ${moduleName} = new ${moduleClassName(moduleName)}(bridge);\n`);
  });

function moduleClassName(mod: string): string {
  const parts = mod.split('-');
  return parts.map((p) => p.charAt(0).toUpperCase() + p.slice(1)).join('') + 'Module';
}
