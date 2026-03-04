import { Command } from 'commander';
import { input, checkbox } from '@inquirer/prompts';
import pc from 'picocolors';
import { join } from 'node:path';
import { writeFile } from '../utils/fs.js';
import { packageJsonTemplate } from '../templates/package-json.js';
import { tsconfigTemplate } from '../templates/tsconfig.js';
import { bridgeTemplate } from '../templates/bridge.js';

const AVAILABLE_MODULES = [
  { name: 'device', value: 'device' },
  { name: 'storage', value: 'storage' },
  { name: 'secure-storage', value: 'secure-storage' },
  { name: 'ui', value: 'ui' },
];

export const initCommand = new Command('init')
  .description('Initialize a new RynBridge project')
  .action(async () => {
    console.log(pc.bold('\n🏗  RynBridge Project Setup\n'));

    const projectName = await input({
      message: 'Project name:',
      default: 'my-rynbridge-app',
    });

    const modules = await checkbox({
      message: 'Select modules to include:',
      choices: AVAILABLE_MODULES,
    });

    const cwd = process.cwd();
    const projectDir = join(cwd, projectName);

    console.log(pc.dim(`\nCreating project in ${projectDir}...\n`));

    writeFile(
      join(projectDir, 'package.json'),
      packageJsonTemplate(projectName, modules),
    );

    writeFile(join(projectDir, 'tsconfig.json'), tsconfigTemplate());

    writeFile(
      join(projectDir, 'src', 'bridge.ts'),
      bridgeTemplate(modules),
    );

    console.log(pc.green(`\n✓ Project "${projectName}" created successfully!`));
    console.log(pc.dim(`\nNext steps:`));
    console.log(`  cd ${projectName}`);
    console.log(`  npm install`);
    console.log(`  npm run build\n`);
  });
