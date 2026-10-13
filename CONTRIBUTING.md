# Contributing

Developer guide for this repository. User documentation lives in `README.md`.

## What this repository contains

- `Containerfile` — image build definition.
- `container-init.sh` — runtime installer, baked into the image and run by `tini` at container start.
- `opencode.json` — OpenCode agent configuration.
- `scripts/` — maintenance scripts (see below).
- `BLUEPRINT.md` — language-agnostic architecture specification.
- `CODEBASE.md` — file-to-component mapping with line references.

## Workflow

Follow the order in `AGENTS.md`: architecture → implementation → testing →
synchronization → zero problems → wrap-up.

1. Update `BLUEPRINT.md` (contracts, components) before writing code for a
   new feature or an architectural change.
2. Implement the change.
3. Run the verification scripts (see below) and fix failures.
4. Update `CODEBASE.md` to match new paths and line references. Remove
   orphaned paths.
5. Commit documentation sync before the feature or fix commit.

## Scripts

All scripts live in `scripts/`, are executable, and run from any directory.

### scripts/bump-version.sh

Increments the `VERSION` file.

Arguments: exactly one of `patch`, `minor`, `major`.

```bash
scripts/bump-version.sh patch   # 0.3.0 -> 0.3.1
scripts/bump-version.sh minor   # 0.3.0 -> 0.4.0
scripts/bump-version.sh major   # 0.3.0 -> 1.0.0
```

### scripts/validate-changelog.sh

Checks that `VERSION` matches the top `## [x.y.z]` header in `CHANGELOG.md`.
Takes no arguments. Exits non-zero on mismatch.

```bash
scripts/validate-changelog.sh
# OK: 0.3.0 matches CHANGELOG
```

### scripts/verify_codebase_sync.sh

Validates `CODEBASE.md` against the repository. Takes no arguments. It
checks two things:

1. Every file path referenced in `CODEBASE.md` tables exists on disk.
2. Every line-number reference (for example "`container-init.sh` line 31"
   or "Lines 24–29: `install_npm_package`") points at a range that
   contains at least one backtick-quoted token from the same row.

Exits non-zero and prints `MISSING:` or `STALE:` lines when a check fails.

```bash
scripts/verify_codebase_sync.sh
# OK: all paths and line references in CODEBASE.md are valid
```

## Changelog and versioning

- `VERSION` holds the current release number.
- `CHANGELOG.md` lists releases newest-first. Each entry starts with a
  `## [x.y.z] - YYYY-MM-DD` header followed by `why`, `model`, and `tags`
  lines, then Added/Changed/Fixed/Removed sections.
- Bump the version with `scripts/bump-version.sh` and add the changelog
  entry in the same change.

## Commit conventions

Use Conventional Commits: `<type>(<scope>): <summary>`. Documentation sync
commits use `docs(sync):` and must precede the feature or fix commit they
describe.

## Verification gate

Before finishing any change, run:

```bash
scripts/verify_codebase_sync.sh
scripts/validate-changelog.sh
```

Both must exit 0.
