#!/usr/bin/env node

/**
 * Bundle size checker for RynBridge packages.
 * Enforces gzipped size limits:
 *   - core: < 5KB (5120 bytes)
 *   - modules: < 3KB (3072 bytes)
 */

import { execSync } from 'node:child_process';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { gzipSync } from 'node:zlib';

const CORE_LIMIT = 5120;
const MODULE_LIMIT = 3072;
const SKIP = ['cli', 'codegen', 'devtools', 'docs'];

const packagesDir = join(process.cwd(), 'packages');
const packages = readdirSync(packagesDir).filter((d) => {
  try {
    return statSync(join(packagesDir, d)).isDirectory() && !SKIP.includes(d);
  } catch {
    return false;
  }
});

let failed = false;
const results = [];

for (const pkg of packages.sort()) {
  const distDir = join(packagesDir, pkg, 'dist');
  let mjs;
  try {
    mjs = readdirSync(distDir).find((f) => f.endsWith('.mjs'));
  } catch {
    continue;
  }
  if (!mjs) continue;

  const content = readFileSync(join(distDir, mjs));
  const raw = content.length;
  const gz = gzipSync(content).length;
  const limit = pkg === 'core' ? CORE_LIMIT : MODULE_LIMIT;
  const pass = gz <= limit;

  if (!pass) failed = true;

  results.push({ pkg, raw, gz, limit, pass });
}

// Print table
console.log('\n  Bundle Size Report\n');
console.log(
  '  ' +
    'Package'.padEnd(22) +
    'Raw'.padStart(8) +
    'Gzip'.padStart(8) +
    'Limit'.padStart(8) +
    '  Status',
);
console.log('  ' + '─'.repeat(56));

for (const r of results) {
  const status = r.pass ? '✓' : '✗ OVER';
  const line =
    '  ' +
    r.pkg.padEnd(22) +
    `${r.raw}B`.padStart(8) +
    `${r.gz}B`.padStart(8) +
    `${r.limit}B`.padStart(8) +
    `  ${status}`;
  console.log(line);
}

console.log();

if (failed) {
  console.error('  ✗ Bundle size check FAILED — some packages exceed the limit.\n');
  process.exit(1);
} else {
  console.log('  ✓ All packages within size limits.\n');
}
