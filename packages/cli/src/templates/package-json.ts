export function packageJsonTemplate(name: string, modules: string[]): string {
  const deps: Record<string, string> = {
    '@rynbridge/core': '^0.1.0',
  };
  for (const mod of modules) {
    deps[`@rynbridge/${mod}`] = '^0.1.0';
  }

  const pkg = {
    name,
    version: '0.1.0',
    private: true,
    type: 'module',
    scripts: {
      build: 'tsc',
      dev: 'tsc --watch',
    },
    dependencies: deps,
    devDependencies: {
      typescript: '^5.7.0',
    },
  };

  return JSON.stringify(pkg, null, 2) + '\n';
}
