export const PANEL_STYLES = `
  .rynbridge-devtools {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 320px;
    background: #1e1e2e;
    color: #cdd6f4;
    font-family: 'SF Mono', 'Fira Code', monospace;
    font-size: 12px;
    z-index: 999999;
    display: flex;
    flex-direction: column;
    border-top: 2px solid #89b4fa;
    transition: transform 0.2s ease;
  }
  .rynbridge-devtools.collapsed {
    transform: translateY(calc(100% - 32px));
  }
  .rynbridge-devtools-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 6px 12px;
    background: #181825;
    border-bottom: 1px solid #313244;
    cursor: pointer;
    user-select: none;
    min-height: 32px;
    box-sizing: border-box;
  }
  .rynbridge-devtools-title {
    font-weight: 600;
    color: #89b4fa;
  }
  .rynbridge-devtools-stats {
    color: #a6adc8;
    font-size: 11px;
  }
  .rynbridge-devtools-filters {
    display: flex;
    gap: 8px;
    padding: 6px 12px;
    background: #11111b;
    border-bottom: 1px solid #313244;
  }
  .rynbridge-devtools-filters select {
    background: #313244;
    color: #cdd6f4;
    border: 1px solid #45475a;
    border-radius: 4px;
    padding: 2px 6px;
    font-size: 11px;
  }
  .rynbridge-devtools-list {
    flex: 1;
    overflow-y: auto;
    padding: 0;
    margin: 0;
    list-style: none;
  }
  .rynbridge-devtools-entry {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 4px 12px;
    border-bottom: 1px solid #181825;
    cursor: pointer;
  }
  .rynbridge-devtools-entry:hover {
    background: #313244;
  }
  .rynbridge-devtools-arrow {
    font-size: 14px;
    width: 20px;
    text-align: center;
  }
  .rynbridge-devtools-arrow.outgoing { color: #f38ba8; }
  .rynbridge-devtools-arrow.incoming { color: #a6e3a1; }
  .rynbridge-devtools-action {
    flex: 1;
    font-weight: 500;
  }
  .rynbridge-devtools-badge {
    padding: 1px 6px;
    border-radius: 3px;
    font-size: 10px;
    font-weight: 600;
  }
  .rynbridge-devtools-badge.pending { background: #f9e2af; color: #1e1e2e; }
  .rynbridge-devtools-badge.success { background: #a6e3a1; color: #1e1e2e; }
  .rynbridge-devtools-badge.error   { background: #f38ba8; color: #1e1e2e; }
  .rynbridge-devtools-badge.timeout { background: #fab387; color: #1e1e2e; }
  .rynbridge-devtools-latency {
    color: #a6adc8;
    font-size: 11px;
    min-width: 50px;
    text-align: right;
  }
  .rynbridge-devtools-detail {
    padding: 8px 12px;
    background: #11111b;
    border-bottom: 1px solid #313244;
    white-space: pre-wrap;
    word-break: break-all;
    font-size: 11px;
    color: #bac2de;
    max-height: 120px;
    overflow-y: auto;
  }
  .rynbridge-devtools-clear {
    background: #45475a;
    color: #cdd6f4;
    border: none;
    border-radius: 4px;
    padding: 2px 8px;
    font-size: 11px;
    cursor: pointer;
  }
`;
