import type { MessageStore } from '../MessageStore.js';
import type { MessageEntry, MessageDirection, MessageStatus } from '../types.js';
import { renderEntry, renderDetail } from './render.js';
import { PANEL_STYLES } from './styles.js';

export class DevToolsPanel {
  private container!: HTMLDivElement;
  private list!: HTMLUListElement;
  private statsEl!: HTMLSpanElement;
  private store: MessageStore;
  private expandedId: string | null = null;
  private filter: {
    module?: string;
    direction?: MessageDirection;
    status?: MessageStatus;
  } = {};

  private constructor(store: MessageStore) {
    this.store = store;
  }

  static attach(store: MessageStore): DevToolsPanel {
    const panel = new DevToolsPanel(store);
    panel.mount();
    return panel;
  }

  private mount(): void {
    // Inject styles
    const style = document.createElement('style');
    style.textContent = PANEL_STYLES;
    document.head.appendChild(style);

    // Container
    this.container = document.createElement('div');
    this.container.className = 'rynbridge-devtools';

    // Header
    const header = document.createElement('div');
    header.className = 'rynbridge-devtools-header';
    header.addEventListener('click', () => {
      this.container.classList.toggle('collapsed');
    });

    const title = document.createElement('span');
    title.className = 'rynbridge-devtools-title';
    title.textContent = 'RynBridge DevTools';

    this.statsEl = document.createElement('span');
    this.statsEl.className = 'rynbridge-devtools-stats';
    this.updateStats();

    header.appendChild(title);
    header.appendChild(this.statsEl);

    // Filters
    const filters = document.createElement('div');
    filters.className = 'rynbridge-devtools-filters';

    const moduleSelect = this.createFilter('Module', ['all', ...this.getModules()], (val) => {
      this.filter.module = val === 'all' ? undefined : val;
      this.refresh();
    });

    const dirSelect = this.createFilter('Direction', ['all', 'outgoing', 'incoming'], (val) => {
      this.filter.direction = val === 'all' ? undefined : (val as MessageDirection);
      this.refresh();
    });

    const statusSelect = this.createFilter(
      'Status',
      ['all', 'pending', 'success', 'error', 'timeout'],
      (val) => {
        this.filter.status = val === 'all' ? undefined : (val as MessageStatus);
        this.refresh();
      },
    );

    const clearBtn = document.createElement('button');
    clearBtn.className = 'rynbridge-devtools-clear';
    clearBtn.textContent = 'Clear';
    clearBtn.addEventListener('click', () => {
      this.store.clear();
    });

    filters.appendChild(moduleSelect);
    filters.appendChild(dirSelect);
    filters.appendChild(statusSelect);
    filters.appendChild(clearBtn);

    // List
    this.list = document.createElement('ul');
    this.list.className = 'rynbridge-devtools-list';

    this.container.appendChild(header);
    this.container.appendChild(filters);
    this.container.appendChild(this.list);
    document.body.appendChild(this.container);

    // Subscribe to store changes
    this.store.subscribe((event) => {
      if (event.type === 'clear') {
        this.list.innerHTML = '';
        this.expandedId = null;
      } else {
        this.refresh();
      }
      this.updateStats();
    });

    // Render existing entries
    this.refresh();
  }

  private refresh(): void {
    const entries = this.hasFilter()
      ? this.store.getFiltered(this.filter)
      : [...this.store.getAll()];

    this.list.innerHTML = '';
    for (const entry of entries) {
      const li = renderEntry(entry);
      li.addEventListener('click', () => this.toggleDetail(entry));
      this.list.appendChild(li);

      if (this.expandedId === entry.id) {
        this.list.appendChild(renderDetail(entry));
      }
    }
  }

  private toggleDetail(entry: MessageEntry): void {
    this.expandedId = this.expandedId === entry.id ? null : entry.id;
    this.refresh();
  }

  private hasFilter(): boolean {
    return !!(this.filter.module || this.filter.direction || this.filter.status);
  }

  private updateStats(): void {
    if (!this.statsEl) return;
    const { count, avgLatency } = this.store.getStats();
    this.statsEl.textContent = `${count} messages | avg ${avgLatency}ms`;
  }

  private getModules(): string[] {
    const modules = new Set<string>();
    for (const entry of this.store.getAll()) {
      modules.add(entry.module);
    }
    return [...modules].sort();
  }

  private createFilter(
    label: string,
    options: string[],
    onChange: (value: string) => void,
  ): HTMLSelectElement {
    const select = document.createElement('select');
    select.title = label;
    for (const opt of options) {
      const option = document.createElement('option');
      option.value = opt;
      option.textContent = opt === 'all' ? `${label}: All` : opt;
      select.appendChild(option);
    }
    select.addEventListener('change', () => onChange(select.value));
    return select;
  }

  detach(): void {
    this.container.remove();
  }
}
