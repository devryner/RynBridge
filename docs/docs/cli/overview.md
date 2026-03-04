---
sidebar_position: 1
---

# CLI

`@rynbridge/cli` — Command-line tool for scaffolding, code generation, and diagnostics.

## Installation

```bash
npm install -g @rynbridge/cli
# or use npx
npx @rynbridge/cli --help
```

## Commands

### `rynbridge init`

Interactive project scaffolding.

```bash
npx rynbridge init
```

Prompts for:
- Project name
- Modules to include (device, storage, secure-storage, ui)

Generates:
- `package.json` with selected dependencies
- `tsconfig.json` with recommended settings
- `src/bridge.ts` with bridge initialization code

### `rynbridge add <module>`

Add a module to your project.

```bash
npx rynbridge add device
```

- Auto-detects package manager (pnpm > yarn > npm)
- Runs the install command
- Prints usage example

### `rynbridge generate`

Generate typed code from JSON Schema contracts.

```bash
npx rynbridge generate [options]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--contracts <dir>` | `./contracts` | Path to contracts directory |
| `--target <target>` | `all` | `typescript`, `swift`, `kotlin`, `markdown`, or `all` |
| `--outdir <dir>` | `./generated` | Output directory |

**Example:**

```bash
# Generate TypeScript types only
npx rynbridge generate --target typescript --outdir src/generated

# Generate for all platforms
npx rynbridge generate --contracts ./contracts --outdir ./generated
```

### `rynbridge doctor`

Check your development environment.

```bash
npx rynbridge doctor
```

Checks:
- Node.js version (>= 20)
- pnpm availability
- `contracts/` directory existence
- Swift toolchain (optional)
- Kotlin toolchain (optional)
