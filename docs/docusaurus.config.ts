import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'RynBridge',
  tagline: 'Lightweight, modular bridge framework for Web ↔ Native communication',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://rynbridge.io',
  baseUrl: '/',

  organizationName: 'rynbridge',
  projectName: 'rynbridge',

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: 'docs',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'RynBridge',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: 'https://github.com/user/rynbridge',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            { label: 'Getting Started', to: '/docs/getting-started/installation' },
            { label: 'API Reference', to: '/docs/api/core' },
          ],
        },
        {
          title: 'Tools',
          items: [
            { label: 'CLI', to: '/docs/cli/overview' },
            { label: 'DevTools', to: '/docs/devtools/overview' },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} RynBridge. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['swift', 'kotlin', 'bash'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
