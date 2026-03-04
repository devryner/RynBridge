export function tsconfigTemplate(): string {
  const config = {
    compilerOptions: {
      target: 'ES2022',
      module: 'ES2022',
      moduleResolution: 'bundler',
      lib: ['ES2022', 'DOM'],
      strict: true,
      esModuleInterop: true,
      skipLibCheck: true,
      declaration: true,
      outDir: './dist',
      rootDir: './src',
    },
    include: ['src'],
  };

  return JSON.stringify(config, null, 2) + '\n';
}
