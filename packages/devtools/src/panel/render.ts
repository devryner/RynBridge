import type { MessageEntry } from '../types.js';

export function renderEntry(entry: MessageEntry): HTMLLIElement {
  const li = document.createElement('li');
  li.className = 'rynbridge-devtools-entry';
  li.dataset.id = entry.id;

  const arrow = document.createElement('span');
  arrow.className = `rynbridge-devtools-arrow ${entry.direction}`;
  arrow.textContent = entry.direction === 'outgoing' ? '↑' : '↓';

  const action = document.createElement('span');
  action.className = 'rynbridge-devtools-action';
  action.textContent = `${entry.module}.${entry.action}`;

  const badge = document.createElement('span');
  badge.className = `rynbridge-devtools-badge ${entry.status}`;
  badge.textContent = entry.status;

  const latency = document.createElement('span');
  latency.className = 'rynbridge-devtools-latency';
  latency.textContent = entry.latency !== undefined ? `${entry.latency}ms` : '—';

  li.appendChild(arrow);
  li.appendChild(action);
  li.appendChild(badge);
  li.appendChild(latency);

  return li;
}

export function renderDetail(entry: MessageEntry): HTMLDivElement {
  const div = document.createElement('div');
  div.className = 'rynbridge-devtools-detail';

  const data: Record<string, unknown> = {
    id: entry.id,
    direction: entry.direction,
    payload: entry.payload,
  };
  if (entry.responsePayload) {
    data.response = entry.responsePayload;
  }
  if (entry.error) {
    data.error = entry.error;
  }

  div.textContent = JSON.stringify(data, null, 2);
  return div;
}
