import { Command } from 'commander';
import { resolve, join } from 'node:path';
import pc from 'picocolors';
import {
  loadSchemas,
  generateTypeScript,
  generateSwift,
  generateKotlin,
  generateMarkdown,
} from '@rynbridge/codegen';
import { writeFile } from '../utils/fs.js';

type Target = 'typescript' | 'swift' | 'kotlin' | 'markdown' | 'all';

const GENERATORS: Record<Exclude<Target, 'all'>, { fn: typeof generateTypeScript; ext: string }> = {
  typescript: { fn: generateTypeScript, ext: '.ts' },
  swift: { fn: generateSwift, ext: '.swift' },
  kotlin: { fn: generateKotlin, ext: '.kt' },
  markdown: { fn: generateMarkdown, ext: '.md' },
};

export const generateCommand = new Command('generate')
  .description('Generate typed code from contract schemas')
  .option('--contracts <dir>', 'Path to contracts directory', './contracts')
  .option('--target <target>', 'Target: typescript|swift|kotlin|markdown|all', 'all')
  .option('--outdir <dir>', 'Output directory', './generated')
  .action((opts: { contracts: string; target: Target; outdir: string }) => {
    const contractsDir = resolve(opts.contracts);
    const outDir = resolve(opts.outdir);

    console.log(pc.dim(`\nLoading schemas from ${contractsDir}...`));

    let schemas;
    try {
      schemas = loadSchemas(contractsDir);
    } catch (err) {
      console.error(pc.red(`\n✗ ${(err as Error).message}`));
      process.exit(1);
    }

    const moduleNames = Object.keys(schemas);
    console.log(pc.dim(`Found modules: ${moduleNames.join(', ')}\n`));

    const targets: Array<Exclude<Target, 'all'>> =
      opts.target === 'all'
        ? ['typescript', 'swift', 'kotlin', 'markdown']
        : [opts.target as Exclude<Target, 'all'>];

    let fileCount = 0;
    for (const target of targets) {
      const gen = GENERATORS[target];
      for (const moduleName of moduleNames) {
        const output = gen.fn({ moduleName, actions: schemas[moduleName] });
        const filePath = join(outDir, target, `${moduleName}${gen.ext}`);
        writeFile(filePath, output);
        fileCount++;
      }
    }

    console.log(pc.green(`\n✓ Generated ${fileCount} files in ${outDir}\n`));
  });
