# Changelog

## [0.3.1] - 2026-10-13

- **why:** Sync docs with container state and close rule-driven doc gaps
- **model:** kompis/qwen3.8-flash-next-iq3_s
- **tags:** docs, sync, rules, scripts

### Added

- Add `CONTRIBUTING.md` with script usage and the developer workflow
- Add line-reference checks to `scripts/verify_codebase_sync.sh`
- Track the memory skill index under `docs/memory/`
- Add OpenSCAD, xauth, and Xvfb section to `README.md`

### Changed

- Sync `BLUEPRINT.md` APT list, playwright-cli skill step, and disabled `@playwright/mcp`
- Fix stale `container-init.sh` line references and add `--shm-size=2gb` in `CODEBASE.md`
- Restructure `.opencode/RULES.md` (renumbered rules, commit consent, verification gate, documentation separation)

## [0.3.0] - 2026-08-11

- **why:** Add openscad, xauth, xvfb to container and sync intent-based commenting rule
- **model:** kompis/qwen-3.6-think-coding-mtp
- **tags:** container, rules, docs

### Added

- Add `openscad`, `xauth`, `xvfb` to container packages (`Containerfile`)
- Add rule 27 (intent-based commenting) to `.opencode/RULES.md`

### Changed

- Comment out playwright MCP configuration in `opencode.json`

## [0.2.2] - 2026-07-19

- **why:** Fix documentation inconsistencies between code and docs
- **model:** deepseek/deepseek-v4-flash
- **tags:** docs, sync, blueprint, codebase

### Added

- Create `scripts/verify_codebase_sync.sh` to validate CODEBASE.md path references
- Add `o2cfg` to BLUEPRINT.md External Dependencies table
- Add `o2cfg` and `@playwright/cli` to README.md upgrade package list

### Fixed

- Sync CODEBASE.md `autoupdate` value with opencode.json (`"notify"` → `false`)
- Sync CODEBASE.md `instructions` with opencode.json (add missing `AGENTS.md` reference)
- Add missing `scripts/` directory and `CHANGELOG.md`, `VERSION` files to CODEBASE.md directory tree

## [0.2.1] - 2026-07-19

- **why:** Add playwright-cli browser automation and sync documentation
- **model:** deepseek-v4-flash-free
- **tags:** docs, playwright, sync

### Added

- Add `playwright-cli` section to `README.md` with browser installation instructions
- Add `@playwright/cli` npm package and skill installation to `container-init.sh`

### Changed

- Sync `BLUEPRINT.md` and `CODEBASE.md` with `@playwright/cli` and `o2cfg` tool references
- Add `o2cfg` to developer tools list in `README.md` intro

## [0.2.0] - 2026-07-18

- **why:** Add Playwright browser automation via MCP and switch base image to node:26
- **model:** deepseek-v4-flash-free
- **tags:** container, playwright, mcp, base-image, breaking

### Breaking Changes

- Base image changed from `debian:stable-slim` to `node:26`. Old volume data in `/home/opencode` is incompatible. You must start with a clean home volume: `podman volume rm opencode` before running the new image.
- npm packages switched from global to local install (`$HOME/node_modules`). Existing global package state is no longer valid.

### Added

- Playwright MCP server config with Chromium to `opencode.json`
- Browser dependency installation step to Containerfile
- Playwright artifact patterns to `.gitignore`

### Changed

- Switch base image from `debian:stable-slim` to `node:26` in Containerfile, removing NVM dependency
- Move npm packages from global to local install in `container-init.sh`
- Add `--shm-size=2gb` to podman run examples in `README.md`
- Move `HOME` env var after `WORKDIR` in Containerfile

### Removed

- NVM install and Node LTS installation from `container-init.sh`
- `NVM_VERSION` and `NVM_DIR` environment variables from Containerfile

## [0.1.3] - 2026-07-16

- **why:** Workspace hygiene: update .gitignore, add changelog validation, bump version before commit
- **model:** github-copilot/gpt-5-mini
- **tags:** chore, release, docs

### Added

- Add `scripts/validate-changelog.sh` to verify VERSION matches the top changelog entry

### Changed

- Update `.gitignore` to ignore temporary AI/workflow artifacts (`.qa-error.log`, `.handoff/`)
- Bump `VERSION` to `0.1.3`

## [0.1.2] - 2026-07-09

- **why:** Fix condition evaluation order in init script guards
- **model:** qwen-3.6-think-coding
- **tags:** container, init-script, bugfix

### Fixed

- Reorder `||` conditions in install guards to check command existence first, then UPGRADE flag

## [0.1.1] - 2026-07-09

- **why:** Add o2cfg tool and sync documentation
- **model:** qwen-3.6-think-coding
- **tags:** container, uv-tools, docs

### Added

- Add `o2cfg` uv tool to `container-init.sh`

### Changed

- Update `README.md` to reflect installed tools (ralph-loop, gitsem, o2cfg)
- Simplify build-arg reference in `README.md` to only `NVM_VERSION` and `UV_VERSION`

## [0.1.0] - 2026-07-05

- **why:** Refactor init script with helper functions and update Containerfile
- **model:** qwen-3.6-think-coding
- **tags:** refactor, container, init-script

### Changed

- Replace fragile `(! $UPGRADE && cmd) || cmd2` pattern with `install_npm_package` and `install_uv_tool` helper functions
- Add upgrade support to Node LTS installation
- Remove unused ENV variables from Containerfile (`PIPENV_VERSION`, `RUFF_VERSION`, `OPENCODE_VERSION`, `BIOME_VERSION`)
- Update `UV_VERSION` from `0.11.7` to `0.11.26`
- Sync `BLUEPRINT.md` and `CODEBASE.md` with code changes
