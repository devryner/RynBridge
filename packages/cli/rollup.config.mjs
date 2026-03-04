import typescript from '@rollup/plugin-typescript';

export default [
  {
    input: 'src/cli.ts',
    output: {
      file: 'dist/cli.mjs',
      format: 'es',
      sourcemap: true,
      banner: '#!/usr/bin/env node',
    },
    external: [
      'commander',
      '@inquirer/prompts',
      'picocolors',
      '@rynbridge/codegen',
      'node:fs',
      'node:path',
      'node:child_process',
    ],
    plugins: [
      typescript({
        tsconfig: './tsconfig.json',
        declaration: false,
      }),
    ],
  },
];
