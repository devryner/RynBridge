export function bridgeTemplate(modules: string[]): string {
  const imports = [
    `import { RynBridge, WebViewTransport } from '@rynbridge/core';`,
  ];

  const moduleInits: string[] = [];

  for (const mod of modules) {
    const className = moduleClassName(mod);
    imports.push(`import { ${className} } from '@rynbridge/${mod}';`);
    moduleInits.push(`export const ${mod} = new ${className}(bridge);`);
  }

  return `${imports.join('\n')}

const transport = new WebViewTransport();
export const bridge = new RynBridge({}, transport);

${moduleInits.join('\n')}
`;
}

function moduleClassName(mod: string): string {
  const parts = mod.split('-');
  return parts.map((p) => p.charAt(0).toUpperCase() + p.slice(1)).join('') + 'Module';
}
