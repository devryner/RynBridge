import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'getting-started/installation',
        'getting-started/quick-start',
      ],
    },
    {
      type: 'category',
      label: 'Core Concepts',
      items: [
        'core-concepts/architecture',
        'core-concepts/message-protocol',
        'core-concepts/modules',
      ],
    },
    {
      type: 'category',
      label: 'API Reference',
      items: [
        'api/core',
        'api/device',
        'api/storage',
        'api/secure-storage',
        'api/ui',
        'api/auth',
        'api/push',
        'api/payment',
        'api/media',
        'api/crypto',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      items: [
        'guides/integration',
      ],
    },
    {
      type: 'category',
      label: 'Platform Guides',
      items: [
        'platform-guides/web',
        'platform-guides/ios',
        'platform-guides/android',
      ],
    },
    {
      type: 'category',
      label: 'CLI',
      items: ['cli/overview'],
    },
    {
      type: 'category',
      label: 'DevTools',
      items: ['devtools/overview'],
    },
  ],
};

export default sidebars;
