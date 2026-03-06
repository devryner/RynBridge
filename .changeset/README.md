# Changesets

This folder is managed by [Changesets](https://github.com/changesets/changesets).

To add a changeset, run:

```bash
pnpm changeset
```

This will prompt you to select packages and describe your changes. The changeset files are committed and later consumed by `pnpm version-packages` to bump versions and update changelogs.
