# Changelog

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
