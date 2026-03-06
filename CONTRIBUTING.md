# Contributing to RynBridge

Thank you for considering contributing to RynBridge! This guide will help you get started.

## Development Setup

### Prerequisites

- Node.js 20+ (see `.nvmrc`)
- pnpm 9.15.4+
- Xcode 16+ (for iOS)
- Android Studio / JDK 17 (for Android)

### Getting Started

```bash
git clone https://github.com/user/rynbridge.git
cd rynbridge
pnpm install
pnpm build
pnpm test
```

## Project Structure

```
rynbridge/
├── contracts/          # JSON Schema contracts (source of truth)
├── packages/           # Web SDK (TypeScript)
│   ├── core/
│   ├── device/
│   ├── storage/
│   └── ...
├── ios/                # iOS SDK (Swift)
│   ├── Sources/
│   └── Tests/
├── android/            # Android SDK (Kotlin)
│   ├── core/
│   └── ...
└── scripts/            # CI/tooling scripts
```

## Workflow

1. **Fork** the repository and create a feature branch from `main`.
2. **Contract-first**: If changing a bridge API, update the JSON Schema in `contracts/` first.
3. **Implement** the change across relevant platforms (Web, iOS, Android).
4. **Test** your changes:
   ```bash
   pnpm test          # Web
   cd ios && swift test        # iOS
   cd android && ./gradlew test  # Android
   ```
5. **Lint**: `pnpm lint`
6. **Bundle size**: `pnpm check:size` — core must be < 5KB gzip, modules < 3KB gzip.
7. **API consistency**: `pnpm check:api` — all platforms must implement contract actions.
8. **Commit** using [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` new feature
   - `fix:` bug fix
   - `docs:` documentation only
   - `refactor:` code change that neither fixes a bug nor adds a feature
   - `test:` adding or updating tests
   - `chore:` maintenance tasks
9. Open a **Pull Request** against `main`.

## Adding a New Module

1. Create the JSON Schema contract in `contracts/<module-name>/`.
2. Implement the Web package in `packages/<module-name>/`.
3. Implement the iOS target in `ios/Sources/RynBridge<ModuleName>/`.
4. Implement the Android module in `android/<module-name>/`.
5. Add the module to `packages/cli/src/commands/doctor.ts` check lists.
6. Run `pnpm check:api` to verify cross-platform consistency.

## Code Style

- **TypeScript**: ESLint + Prettier (configured per package)
- **Swift**: Standard Swift conventions, `@unchecked Sendable` where needed
- **Kotlin**: ktlint-compatible style

## Reporting Issues

Use [GitHub Issues](https://github.com/user/rynbridge/issues) with the provided templates.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
