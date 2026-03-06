#!/usr/bin/env node

/**
 * API consistency checker for RynBridge.
 * Verifies that each contract module has matching implementations
 * across Web SDK, iOS, and Android platforms.
 */

import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const root = process.cwd();
const contractsDir = join(root, 'contracts');

// Module name mappings between contract dir names and platform conventions
function toWebPkg(contractName) {
  // Contract dirs use either kebab-case or camelCase
  const map = { backgroundTask: 'background-task', secureStorage: 'secure-storage' };
  return map[contractName] ?? contractName;
}

function toIosTarget(contractName) {
  // Convert contract dir name to iOS SPM target name
  // e.g. "secure-storage" → "RynBridgeSecureStorage", "backgroundTask" → "RynBridgeBackgroundTask"
  const pascal = contractName
    .split(/[-]/)
    .map((s) => s.charAt(0).toUpperCase() + s.slice(1))
    .join('');
  return `RynBridge${pascal}`;
}

function toAndroidDir(contractName) {
  const map = { backgroundTask: 'background-task', secureStorage: 'secure-storage' };
  return map[contractName] ?? contractName;
}

function readText(path) {
  try {
    return readFileSync(path, 'utf-8');
  } catch {
    return null;
  }
}

const contractModules = readdirSync(contractsDir, { withFileTypes: true })
  .filter((d) => d.isDirectory() && d.name !== 'core')
  .map((d) => d.name);

let totalChecks = 0;
let passCount = 0;
let warnCount = 0;
let failCount = 0;

const issues = [];

console.log('\n  API Consistency Report\n');

for (const mod of contractModules.sort()) {
  const schemaDir = join(contractsDir, mod);
  const schemas = readdirSync(schemaDir).filter((f) => f.endsWith('.schema.json'));
  const actions = schemas
    .filter((f) => f.endsWith('.request.schema.json'))
    .map((f) => f.replace('.request.schema.json', ''));

  if (actions.length === 0) continue;

  // Separate events from request-response actions
  const reqActions = actions.filter((a) => !a.startsWith('on'));
  const events = actions.filter((a) => a.startsWith('on'));

  // --- Web SDK check ---
  const webPkg = toWebPkg(mod);
  const webSrcDir = join(root, 'packages', webPkg, 'src');
  let webSource = '';
  if (existsSync(webSrcDir)) {
    const tsFiles = readdirSync(webSrcDir).filter(
      (f) => f.endsWith('.ts') && !f.includes('.test.') && !f.includes('types'),
    );
    for (const f of tsFiles) {
      webSource += readText(join(webSrcDir, f)) ?? '';
    }
  }

  const webMissing = reqActions.filter(
    (a) => !webSource.includes(`'${a}'`) && !webSource.includes(`"${a}"`),
  );

  totalChecks++;
  if (!existsSync(webSrcDir)) {
    failCount++;
    issues.push(`${mod}: web package missing`);
  } else if (webMissing.length > 0) {
    warnCount++;
    issues.push(`${mod}: web SDK missing actions: ${webMissing.join(', ')}`);
  } else {
    passCount++;
  }

  // --- iOS check ---
  const iosTarget = toIosTarget(mod);
  const iosDir = join(root, 'ios', 'Sources', iosTarget);
  let iosSource = '';
  if (existsSync(iosDir)) {
    const swiftFiles = readdirSync(iosDir).filter((f) => f.endsWith('.swift') && !f.includes('Types'));
    for (const f of swiftFiles) {
      iosSource += readText(join(iosDir, f)) ?? '';
    }
  }

  const iosMissing = reqActions.filter(
    (a) => !iosSource.includes(`"${a}"`) && !iosSource.includes(`"${a}"`),
  );

  totalChecks++;
  if (!existsSync(iosDir)) {
    warnCount++;
    issues.push(`${mod}: iOS target ${iosTarget} not found`);
  } else if (iosMissing.length > 0) {
    warnCount++;
    issues.push(`${mod}: iOS missing actions: ${iosMissing.join(', ')}`);
  } else {
    passCount++;
  }

  // --- Android check ---
  const androidDir = toAndroidDir(mod);
  const androidSrcDir = join(root, 'android', androidDir, 'src', 'main', 'kotlin');
  let androidSource = '';
  if (existsSync(androidSrcDir)) {
    const findKotlinFiles = (dir) => {
      const entries = readdirSync(dir, { withFileTypes: true });
      for (const e of entries) {
        const p = join(dir, e.name);
        if (e.isDirectory()) findKotlinFiles(p);
        else if (e.name.endsWith('.kt') && !e.name.includes('Types')) {
          androidSource += readText(p) ?? '';
        }
      }
    };
    findKotlinFiles(androidSrcDir);
  }

  const androidMissing = reqActions.filter(
    (a) => !androidSource.includes(`"${a}"`) && !androidSource.includes(`"${a}"`),
  );

  totalChecks++;
  if (!existsSync(androidSrcDir)) {
    warnCount++;
    issues.push(`${mod}: Android module ${androidDir} not found`);
  } else if (androidMissing.length > 0) {
    warnCount++;
    issues.push(`${mod}: Android missing actions: ${androidMissing.join(', ')}`);
  } else {
    passCount++;
  }

  // Print module summary
  const webStatus = !existsSync(webSrcDir) ? '✗' : webMissing.length > 0 ? '⚠' : '✓';
  const iosStatus = !existsSync(iosDir) ? '⚠' : iosMissing.length > 0 ? '⚠' : '✓';
  const androidStatus = !existsSync(androidSrcDir) ? '⚠' : androidMissing.length > 0 ? '⚠' : '✓';

  console.log(
    `  ${mod.padEnd(18)} Web:${webStatus}  iOS:${iosStatus}  Android:${androidStatus}  (${reqActions.length} actions, ${events.length} events)`,
  );
}

console.log();

if (issues.length > 0) {
  console.log('  Issues:');
  for (const issue of issues) {
    console.log(`    ⚠ ${issue}`);
  }
  console.log();
}

console.log(`  ${passCount} passed · ${warnCount} warnings · ${failCount} failed`);
console.log(`  ${totalChecks} total checks across ${contractModules.length} modules\n`);

if (failCount > 0) {
  process.exit(1);
}
