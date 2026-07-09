# Changelog

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
