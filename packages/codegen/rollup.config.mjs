import typescript from '@rollup/plugin-typescript';
import dts from 'rollup-plugin-dts';

export default [
  {
    input: 'src/index.ts',
    output: [
      {
        file: 'dist/index.mjs',
        format: 'es',
        sourcemap: true,
      },
      {
        file: 'dist/index.cjs',
        format: 'cjs',
        sourcemap: true,
      },
    ],
    external: ['glob', 'node:fs', 'node:path'],
    plugins: [
      typescript({
        tsconfig: './tsconfig.json',
        declaration: false,
      }),
    ],
  },
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/index.d.ts',
      format: 'es',
    },
    external: ['glob', 'node:fs', 'node:path'],
    plugins: [dts()],
  },
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/index.d.cts',
      format: 'cjs',
    },
    external: ['glob', 'node:fs', 'node:path'],
    plugins: [dts()],
  },
];
