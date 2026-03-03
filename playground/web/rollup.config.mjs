import typescript from '@rollup/plugin-typescript';
import resolve from '@rollup/plugin-node-resolve';
import { readFileSync, mkdirSync, writeFileSync } from 'fs';
import { dirname } from 'path';

function copyHtml() {
  return {
    name: 'copy-html',
    writeBundle(options) {
      const html = readFileSync('src/index.html', 'utf-8');
      const outDir = dirname(options.file ?? 'dist/playground.js');
      mkdirSync(outDir, { recursive: true });
      writeFileSync(`${outDir}/index.html`, html);
    },
  };
}

export default {
  input: 'src/main.ts',
  output: {
    file: 'dist/playground.js',
    format: 'iife',
    name: 'RynBridgePlayground',
    sourcemap: true,
  },
  plugins: [
    resolve(),
    typescript({
      tsconfig: './tsconfig.json',
      declaration: false,
      sourceMap: true,
    }),
    copyHtml(),
  ],
};
