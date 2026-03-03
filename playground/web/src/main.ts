import { RynBridge, WebViewTransport } from '@rynbridge/core';
import { DeviceModule } from '@rynbridge/device';
import { StorageModule } from '@rynbridge/storage';
import { SecureStorageModule } from '@rynbridge/secure-storage';
import { UIModule } from '@rynbridge/ui';

// --- Initialize Bridge ---
const transport = new WebViewTransport();
const bridge = new RynBridge({}, transport);

const device = new DeviceModule(bridge);
const storage = new StorageModule(bridge);
const secureStorage = new SecureStorageModule(bridge);
const ui = new UIModule(bridge);

// --- Logging ---
function log(type: 'info' | 'success' | 'error', message: string, data?: unknown): void {
  const logPanel = document.getElementById('log-panel')!;
  const entry = document.createElement('div');
  entry.className = `log-entry log-${type}`;
  const time = new Date().toLocaleTimeString('en-US', { hour12: false });
  const dataStr = data !== undefined ? `\n${JSON.stringify(data, null, 2)}` : '';
  entry.textContent = `[${time}] ${message}${dataStr}`;
  logPanel.appendChild(entry);
  logPanel.scrollTop = logPanel.scrollHeight;
}

function showResult(data: unknown): void {
  const resultPanel = document.getElementById('result-panel')!;
  resultPanel.textContent = JSON.stringify(data, null, 2);
}

async function run(label: string, fn: () => Promise<unknown> | void): Promise<void> {
  log('info', `${label}...`);
  try {
    const result = await fn();
    if (result !== undefined) {
      showResult(result);
      log('success', `${label} OK`, result);
    } else {
      showResult('(void)');
      log('success', `${label} OK`);
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    showResult({ error: message });
    log('error', `${label} FAILED: ${message}`);
  }
}

// --- Input helpers ---
function getInput(id: string): string {
  return (document.getElementById(id) as HTMLInputElement).value;
}

// --- Device ---
document.getElementById('btn-device-getInfo')!.addEventListener('click', () => {
  run('device.getInfo', () => device.getInfo());
});

document.getElementById('btn-device-getBattery')!.addEventListener('click', () => {
  run('device.getBattery', () => device.getBattery());
});

document.getElementById('btn-device-getScreen')!.addEventListener('click', () => {
  run('device.getScreen', () => device.getScreen());
});

document.getElementById('btn-device-vibrate')!.addEventListener('click', () => {
  run('device.vibrate', () => { device.vibrate(); });
});

// --- Storage ---
document.getElementById('btn-storage-set')!.addEventListener('click', () => {
  const key = getInput('storage-key');
  const value = getInput('storage-value');
  run(`storage.set("${key}", "${value}")`, () => storage.set(key, value));
});

document.getElementById('btn-storage-get')!.addEventListener('click', () => {
  const key = getInput('storage-key');
  run(`storage.get("${key}")`, () => storage.get(key));
});

document.getElementById('btn-storage-remove')!.addEventListener('click', () => {
  const key = getInput('storage-key');
  run(`storage.remove("${key}")`, () => storage.remove(key));
});

document.getElementById('btn-storage-keys')!.addEventListener('click', () => {
  run('storage.keys', () => storage.keys());
});

document.getElementById('btn-storage-clear')!.addEventListener('click', () => {
  run('storage.clear', () => storage.clear());
});

// --- Secure Storage ---
document.getElementById('btn-secure-set')!.addEventListener('click', () => {
  const key = getInput('secure-key');
  const value = getInput('secure-value');
  run(`secureStorage.set("${key}", "${value}")`, () => secureStorage.set(key, value));
});

document.getElementById('btn-secure-get')!.addEventListener('click', () => {
  const key = getInput('secure-key');
  run(`secureStorage.get("${key}")`, () => secureStorage.get(key));
});

document.getElementById('btn-secure-remove')!.addEventListener('click', () => {
  const key = getInput('secure-key');
  run(`secureStorage.remove("${key}")`, () => secureStorage.remove(key));
});

document.getElementById('btn-secure-has')!.addEventListener('click', () => {
  const key = getInput('secure-key');
  run(`secureStorage.has("${key}")`, () => secureStorage.has(key));
});

// --- UI ---
document.getElementById('btn-ui-showAlert')!.addEventListener('click', () => {
  run('ui.showAlert', () =>
    ui.showAlert({ title: 'Hello', message: 'This is a native alert.' }),
  );
});

document.getElementById('btn-ui-showConfirm')!.addEventListener('click', () => {
  run('ui.showConfirm', () =>
    ui.showConfirm({ title: 'Confirm', message: 'Do you agree?' }),
  );
});

document.getElementById('btn-ui-showToast')!.addEventListener('click', () => {
  run('ui.showToast', () => {
    ui.showToast({ message: 'Hello from WebView!' });
  });
});

document.getElementById('btn-ui-showActionSheet')!.addEventListener('click', () => {
  run('ui.showActionSheet', () =>
    ui.showActionSheet({ title: 'Choose', options: ['Option A', 'Option B', 'Option C'] }),
  );
});

// --- Clear log ---
document.getElementById('btn-clear-log')!.addEventListener('click', () => {
  document.getElementById('log-panel')!.innerHTML = '';
  document.getElementById('result-panel')!.textContent = '';
});

log('info', 'RynBridge Playground initialized');
