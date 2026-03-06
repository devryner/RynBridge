import { Command } from 'commander';
import { execSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import pc from 'picocolors';

type Status = 'pass' | 'warn' | 'fail';

interface CheckResult {
  name: string;
  status: Status;
  message?: string;
}

interface CheckGroup {
  title: string;
  checks: () => CheckResult[];
}

const MODULES = [
  'device', 'storage', 'secure-storage', 'ui', 'webview',
  'auth', 'push', 'payment', 'media', 'crypto',
  'calendar', 'contacts', 'share', 'navigation', 'analytics',
  'speech', 'translation', 'bluetooth', 'health', 'background-task',
] as const;

const SUB_PACKAGES: Record<string, string[]> = {
  auth: ['auth-google', 'auth-kakao'],
  push: ['push-fcm'],
  payment: ['payment-google-play'],
};

const EXTERNAL_SDKS: Record<string, { catalogAlias: string; description: string }> = {
  'auth-google': { catalogAlias: 'credentials', description: 'Credential Manager / Google Identity' },
  'auth-kakao': { catalogAlias: 'kakao', description: 'Kakao SDK' },
  'push-fcm': { catalogAlias: 'firebase', description: 'Firebase Cloud Messaging' },
  'payment-google-play': { catalogAlias: 'billing', description: 'Google Play Billing' },
};

const IOS_PERMISSION_KEYS: Record<string, string[]> = {
  health: ['NSHealthShareUsageDescription', 'NSHealthUpdateUsageDescription'],
  bluetooth: ['NSBluetoothAlwaysUsageDescription'],
  contacts: ['NSContactsUsageDescription'],
  calendar: ['NSCalendarsUsageDescription', 'NSCalendarsWriteOnlyAccessUsageDescription'],
  speech: ['NSSpeechRecognitionUsageDescription', 'NSMicrophoneUsageDescription'],
  media: ['NSPhotoLibraryUsageDescription', 'NSCameraUsageDescription'],
};

const ANDROID_PERMISSIONS: Record<string, string[]> = {
  bluetooth: ['android.permission.BLUETOOTH_SCAN', 'android.permission.BLUETOOTH_CONNECT'],
  contacts: ['android.permission.READ_CONTACTS'],
  calendar: ['android.permission.READ_CALENDAR'],
  health: ['android.permission.health.READ_STEPS'],
  speech: ['android.permission.RECORD_AUDIO'],
  media: ['android.permission.CAMERA', 'android.permission.READ_MEDIA_IMAGES'],
};

function rootDir(): string {
  return process.cwd();
}

function readJson(path: string): Record<string, unknown> | null {
  try {
    return JSON.parse(readFileSync(path, 'utf-8'));
  } catch {
    return null;
  }
}

function readText(path: string): string | null {
  try {
    return readFileSync(path, 'utf-8');
  } catch {
    return null;
  }
}

// ── Check Group 1: Environment ──────────────────────────────────────

function checkEnvironment(): CheckResult[] {
  const results: CheckResult[] = [];

  // Node.js
  try {
    const version = execSync('node --version', { encoding: 'utf-8' }).trim();
    const major = parseInt(version.replace('v', ''), 10);
    if (major < 20) {
      results.push({ name: 'Node.js', status: 'fail', message: `${version} (requires >= 20)` });
    } else {
      results.push({ name: 'Node.js', status: 'pass', message: version });
    }
  } catch {
    results.push({ name: 'Node.js', status: 'fail', message: 'not found' });
  }

  // pnpm
  try {
    const version = execSync('pnpm --version', { encoding: 'utf-8' }).trim();
    results.push({ name: 'pnpm', status: 'pass', message: `v${version}` });
  } catch {
    results.push({ name: 'pnpm', status: 'fail', message: 'not found (install: npm i -g pnpm)' });
  }

  // Swift
  try {
    execSync('swift --version', { encoding: 'utf-8' });
    results.push({ name: 'Swift toolchain', status: 'pass' });
  } catch {
    results.push({ name: 'Swift toolchain', status: 'warn', message: 'not found (optional, for iOS)' });
  }

  // Kotlin / Gradle
  try {
    const gradlew = join(rootDir(), 'android', 'gradlew');
    if (existsSync(gradlew)) {
      results.push({ name: 'Android Gradle wrapper', status: 'pass' });
    } else {
      results.push({ name: 'Android Gradle wrapper', status: 'warn', message: 'android/gradlew not found' });
    }
  } catch {
    results.push({ name: 'Android Gradle wrapper', status: 'warn', message: 'check failed' });
  }

  return results;
}

// ── Check Group 2: Module Dependency Verification ───────────────────

function checkModuleDependencies(): CheckResult[] {
  const results: CheckResult[] = [];
  const root = rootDir();

  // Check core package exists
  const corePkg = readJson(join(root, 'packages', 'core', 'package.json'));
  if (!corePkg) {
    results.push({ name: '@rynbridge/core', status: 'fail', message: 'package.json not found' });
    return results;
  }
  const coreVersion = corePkg['version'] as string;
  results.push({ name: '@rynbridge/core', status: 'pass', message: `v${coreVersion}` });

  // Check each module has core as peerDependency
  for (const mod of MODULES) {
    const pkgPath = join(root, 'packages', mod, 'package.json');
    const pkg = readJson(pkgPath);
    if (!pkg) {
      results.push({ name: `@rynbridge/${mod}`, status: 'fail', message: 'package.json not found' });
      continue;
    }

    const peers = pkg['peerDependencies'] as Record<string, string> | undefined;
    if (!peers?.['@rynbridge/core']) {
      results.push({ name: `@rynbridge/${mod}`, status: 'fail', message: 'missing peerDependency on @rynbridge/core' });
      continue;
    }

    // Verify version compatibility (peerDep range should match core version)
    const peerRange = peers['@rynbridge/core'];
    const coreMajorMinor = coreVersion.split('.').slice(0, 2).join('.');
    if (!peerRange.includes(coreMajorMinor.split('.')[0]!)) {
      results.push({ name: `@rynbridge/${mod}`, status: 'warn', message: `peerDep "${peerRange}" may not match core v${coreVersion}` });
    } else {
      results.push({ name: `@rynbridge/${mod}`, status: 'pass' });
    }
  }

  return results;
}

// ── Check Group 3: Sub-package External SDK Verification ────────────

function checkExternalSdks(): CheckResult[] {
  const results: CheckResult[] = [];
  const root = rootDir();

  // Read version catalog for cross-referencing
  const versionCatalog = readText(join(root, 'android', 'gradle', 'libs.versions.toml')) ?? '';

  for (const [subPkg, sdk] of Object.entries(EXTERNAL_SDKS)) {
    const buildFile = join(root, 'android', subPkg, 'build.gradle.kts');
    const content = readText(buildFile);

    if (!content) {
      results.push({ name: `android/${subPkg}`, status: 'warn', message: 'build.gradle.kts not found' });
      continue;
    }

    // Check if build.gradle references the catalog alias or the artifact directly
    const hasRef = content.includes(sdk.catalogAlias) ||
      versionCatalog.includes(sdk.catalogAlias);

    if (hasRef && content.includes('implementation')) {
      results.push({ name: `android/${subPkg}`, status: 'pass', message: sdk.description });
    } else {
      results.push({ name: `android/${subPkg}`, status: 'fail', message: `missing external SDK: ${sdk.description}` });
    }
  }

  // iOS sub-packages
  const iosSubPkgs: Record<string, string> = {
    'RynBridgeAuthApple': 'AuthenticationServices',
    'RynBridgePushAPNs': 'RynBridgePush',
    'RynBridgePaymentStoreKit': 'StoreKit',
  };

  const packageSwift = readText(join(root, 'ios', 'Package.swift'));
  if (packageSwift) {
    for (const [target, dep] of Object.entries(iosSubPkgs)) {
      if (packageSwift.includes(`name: "${target}"`)) {
        results.push({ name: `ios/${target}`, status: 'pass', message: `target defined (${dep})` });
      } else {
        results.push({ name: `ios/${target}`, status: 'warn', message: 'target not found in Package.swift' });
      }
    }
  }

  return results;
}

// ── Check Group 4: Platform Native Config Verification ──────────────

function checkNativeConfig(): CheckResult[] {
  const results: CheckResult[] = [];
  const root = rootDir();

  // iOS: Check Info.plist permission keys (in playground or docs guidance)
  const iosPlistPaths = [
    join(root, 'playground', 'ios', 'RynBridgePlayground', 'Info.plist'),
    join(root, 'playground', 'ios', 'Info.plist'),
  ];

  let plistContent: string | null = null;
  for (const p of iosPlistPaths) {
    plistContent = readText(p);
    if (plistContent) break;
  }

  if (plistContent) {
    for (const [mod, keys] of Object.entries(IOS_PERMISSION_KEYS)) {
      const missing = keys.filter(k => !plistContent!.includes(k));
      if (missing.length === 0) {
        results.push({ name: `iOS/${mod} permissions`, status: 'pass' });
      } else {
        results.push({ name: `iOS/${mod} permissions`, status: 'warn', message: `missing in Info.plist: ${missing.join(', ')}` });
      }
    }
  } else {
    results.push({ name: 'iOS Info.plist', status: 'warn', message: 'playground Info.plist not found (permission keys unchecked)' });
  }

  // Android: Check AndroidManifest.xml permission declarations
  const androidManifestPath = join(root, 'android', 'playground', 'src', 'main', 'AndroidManifest.xml');
  const manifestContent = readText(androidManifestPath);

  if (manifestContent) {
    for (const [mod, perms] of Object.entries(ANDROID_PERMISSIONS)) {
      const missing = perms.filter(p => !manifestContent!.includes(p));
      if (missing.length === 0) {
        results.push({ name: `Android/${mod} permissions`, status: 'pass' });
      } else {
        results.push({ name: `Android/${mod} permissions`, status: 'warn', message: `missing in AndroidManifest: ${missing.map(p => p.split('.').pop()).join(', ')}` });
      }
    }
  } else {
    results.push({ name: 'Android Manifest', status: 'warn', message: 'playground AndroidManifest.xml not found (permissions unchecked)' });
  }

  return results;
}

// ── Check Group 5: Contract ↔ Code Sync ─────────────────────────────

function checkContractSync(): CheckResult[] {
  const results: CheckResult[] = [];
  const root = rootDir();
  const contractsDir = join(root, 'contracts');

  if (!existsSync(contractsDir)) {
    results.push({ name: 'contracts/', status: 'fail', message: 'directory not found' });
    return results;
  }

  const contractModules = readdirSync(contractsDir, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  for (const mod of contractModules) {
    const schemaDir = join(contractsDir, mod);
    const schemas = readdirSync(schemaDir).filter(f => f.endsWith('.schema.json'));

    if (schemas.length === 0) {
      results.push({ name: `contracts/${mod}`, status: 'warn', message: 'no schema files found' });
      continue;
    }

    // Extract action names from request schemas
    const actions = schemas
      .filter(f => f.endsWith('.request.schema.json'))
      .map(f => f.replace('.request.schema.json', ''));

    // Check corresponding response schemas exist (except fire-and-forget like stopScan, completeTask)
    const responseSchemas = new Set(
      schemas.filter(f => f.endsWith('.response.schema.json'))
        .map(f => f.replace('.response.schema.json', ''))
    );

    const missingResponses = actions.filter(a => !responseSchemas.has(a));

    // Check web module has matching actions
    const webModName = mod === 'backgroundTask' ? 'background-task'
      : mod === 'secureStorage' ? 'secure-storage'
      : mod;
    const webModDir = join(root, 'packages', webModName, 'src');

    if (!existsSync(webModDir)) {
      results.push({ name: `contracts/${mod}`, status: 'warn', message: `web package "packages/${webModName}" not found` });
      continue;
    }

    // Read all .ts files in web module to check for action references
    let webSource = '';
    try {
      const tsFiles = readdirSync(webModDir).filter(f => f.endsWith('.ts') && !f.endsWith('.test.ts'));
      for (const f of tsFiles) {
        webSource += readText(join(webModDir, f)) ?? '';
      }
    } catch {
      // ignore
    }

    const missingInWeb = actions.filter(a => {
      // Event streams (on*) use bridge.on() — check for the action name in source
      // Request-response actions use bridge.call() — check for string literal
      return !webSource.includes(`'${a}'`) && !webSource.includes(`"${a}"`);
    });

    // Separate event streams from missing actions (events are expected to use bridge.on)
    const missingEvents = missingInWeb.filter(a => a.startsWith('on'));
    const missingActions = missingInWeb.filter(a => !a.startsWith('on'));

    if (missingActions.length > 0) {
      results.push({ name: `contracts/${mod}`, status: 'warn', message: `actions not found in web SDK: ${missingActions.join(', ')}` });
    } else if (missingEvents.length > 0) {
      results.push({ name: `contracts/${mod}`, status: 'pass', message: `${actions.length} actions (${missingEvents.length} event streams)` });
    } else if (missingResponses.length > 0) {
      results.push({ name: `contracts/${mod}`, status: 'pass', message: `${actions.length} actions (${missingResponses.length} fire-and-forget)` });
    } else {
      results.push({ name: `contracts/${mod}`, status: 'pass', message: `${actions.length} actions synced` });
    }
  }

  return results;
}

// ── Check Group 6: Playground Status ────────────────────────────────

function checkPlayground(): CheckResult[] {
  const results: CheckResult[] = [];
  const root = rootDir();

  // Web playground
  const webPg = join(root, 'playground', 'web');
  if (existsSync(join(webPg, 'package.json'))) {
    const pkg = readJson(join(webPg, 'package.json'));
    const hasBuildScript = (pkg?.['scripts'] as Record<string, string> | undefined)?.['build'];
    results.push({
      name: 'Playground/web',
      status: hasBuildScript ? 'pass' : 'warn',
      message: hasBuildScript ? 'package.json found' : 'missing build script',
    });

    // Check if dist exists (built assets)
    const distDir = join(webPg, 'dist');
    if (existsSync(distDir)) {
      results.push({ name: 'Playground/web build', status: 'pass', message: 'dist/ exists' });
    } else {
      results.push({ name: 'Playground/web build', status: 'warn', message: 'dist/ not found (run build)' });
    }
  } else {
    results.push({ name: 'Playground/web', status: 'warn', message: 'not found' });
  }

  // iOS playground
  const iosPg = join(root, 'playground', 'ios');
  if (existsSync(iosPg)) {
    const hasXcodeProj = readdirSync(iosPg).some(f => f.endsWith('.xcodeproj') || f.endsWith('.xcworkspace'));
    const hasSwiftFiles = existsSync(join(iosPg, 'RynBridgePlayground'));
    results.push({
      name: 'Playground/ios',
      status: hasXcodeProj || hasSwiftFiles ? 'pass' : 'warn',
      message: hasXcodeProj ? 'Xcode project found' : hasSwiftFiles ? 'Swift sources found' : 'no project files',
    });
  } else {
    results.push({ name: 'Playground/ios', status: 'warn', message: 'not found' });
  }

  // Android playground
  const androidPg = join(root, 'android', 'playground');
  if (existsSync(join(androidPg, 'build.gradle.kts'))) {
    results.push({ name: 'Playground/android', status: 'pass', message: 'build.gradle.kts found' });
  } else {
    results.push({ name: 'Playground/android', status: 'warn', message: 'not found' });
  }

  return results;
}

// ── Report ──────────────────────────────────────────────────────────

function printResults(groups: CheckGroup[]): void {
  let passCount = 0;
  let warnCount = 0;
  let failCount = 0;

  for (const group of groups) {
    console.log(pc.bold(`\n  ${group.title}`));
    const results = group.checks();

    for (const r of results) {
      switch (r.status) {
        case 'pass':
          passCount++;
          console.log(`    ${pc.green('✓')} ${r.name}${r.message ? pc.dim(` — ${r.message}`) : ''}`);
          break;
        case 'warn':
          warnCount++;
          console.log(`    ${pc.yellow('⚠')} ${r.name}${r.message ? pc.dim(` — ${r.message}`) : ''}`);
          break;
        case 'fail':
          failCount++;
          console.log(`    ${pc.red('✗')} ${r.name}${r.message ? pc.dim(` — ${r.message}`) : ''}`);
          break;
      }
    }
  }

  // Summary
  console.log(pc.bold('\n  Summary'));
  const parts = [
    pc.green(`${passCount} passed`),
    ...(warnCount > 0 ? [pc.yellow(`${warnCount} warnings`)] : []),
    ...(failCount > 0 ? [pc.red(`${failCount} failed`)] : []),
  ];
  console.log(`    ${parts.join(' · ')}\n`);

  if (failCount > 0) {
    process.exitCode = 1;
  }
}

// ── Command ─────────────────────────────────────────────────────────

export const doctorCommand = new Command('doctor')
  .description('Diagnose project health: dependencies, configs, contracts, and playgrounds')
  .action(() => {
    console.log(pc.bold('\n🩺 RynBridge Doctor\n'));

    const groups: CheckGroup[] = [
      { title: 'Environment', checks: checkEnvironment },
      { title: 'Module Dependencies', checks: checkModuleDependencies },
      { title: 'Sub-package External SDKs', checks: checkExternalSdks },
      { title: 'Platform Native Config', checks: checkNativeConfig },
      { title: 'Contract ↔ Code Sync', checks: checkContractSync },
      { title: 'Playground', checks: checkPlayground },
    ];

    printResults(groups);
  });
