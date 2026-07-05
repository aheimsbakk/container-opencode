# Changelog

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
