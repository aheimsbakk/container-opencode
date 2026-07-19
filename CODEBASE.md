# CODEBASE — Container for OpenCode

## Target Stack

| Aspect | Choice |
| :--- | :--- |
| Base OS | node:26 (Debian-based) |
| Container Runtime | Podman (rootless) |
| Init Process | tini (PID 1) |
| Shell | Bash (login shell) |
| Node Manager | Built-in (node:26 base) |
| Python Package Mgr | pipx (uv), uv tool (pipenv, ruff, ralph-loop, gitsem) |
| npm Packages | opencode-ai, @biomejs/biome, @playwright/cli |
| Config Format | JSON (opencode.json) |

## Directory Tree

```
.
├── AGENTS.md                        # Master rules and workflow for AI agents
├── BLUEPRINT.md                     # Language-agnostic architecture specification
├── CHANGELOG.md                     # Version history
├── CODEBASE.md                      # This file — concrete file-to-component mapping
├── Containerfile                    # Image build definition
├── container-init.sh                # Runtime initialization script (entrypoint)
├── opencode.json                    # OpenCode agent configuration
├── README.md                        # User-facing documentation
├── VERSION                          # Current version number
├── scripts/
│   ├── bump-version.sh              # Version increment helper
│   ├── validate-changelog.sh        # VERSION/CHANGELOG consistency check
│   └── verify_codebase_sync.sh      # CODEBASE.md path verification
└── .opencode/
    └── RULES.md                     # Project-specific rules (referenced by opencode.json)
```

## Physical Path Mappings

### Containerfile → Image Build Layer

| File | Blueprint Component |
| :--- | :--- |
| `Containerfile` | Base OS Layer, Environment Configuration, Entrypoint/CMD |

**Key sections:**
- `FROM node:26` → Base OS + Node.js runtime
- `ENV UV_VERSION` → Software version constraints
- `ENV DEBIAN_FRONTEND`, `LANG`, `LC_ALL`, `HOME`, `PATH`, `TERM`, `EDITOR`, `CGO_ENABLED` → Runtime environment
- `RUN apt-get install ...` → APT packages
- `RUN npx playwright install-deps` → Playwright browser dependencies
- `RUN npm config set min-release-age 7 --global` → npm config
- `RUN locale-gen` → Locale setup
- `RUN ... /etc/bash.bashrc` → Shell niceties
- `ADD container-init.sh /` → Init script baked into image
- `WORKDIR /work` → Working directory
- `VOLUME ["/work", "/home/opencode"]` → Volume declarations
- `ENV HOME=/home/opencode` → Home directory (set after WORKDIR)
- `ENTRYPOINT` / `CMD` → Entrypoint contract

### container-init.sh → Runtime Installer

| File | Blueprint Component |
| :--- | :--- |
| `container-init.sh` | Runtime Installer (npm local, pipx, uv, shell launch) |

**Key logic blocks:**
- Lines 1–9: Upgrade flag detection (`$1 == "upgrade"`)
- Line 12: PATH prepended with `$HOME/.local/bin` and `$HOME/node_modules/.bin`
- Line 15: Skeleton copy (`rsync /etc/skel → /home/opencode`)
- Line 18: npm config (`min-release-age 7 --location=user`)
- Lines 21–28: `install_npm_package` helper function (local install, cd to $HOME, cd /work)
- Lines 30–32: npm local packages (opencode-ai, @biomejs/biome, @playwright/cli)
- Line 34: Append node_modules PATH to `.profile`
- Lines 37–40: uv installation via pipx (conditional on upgrade or missing)
- Lines 43–49: `install_uv_tool` helper function (`_UPGRADE` variable, `--exclude-newer 1 week`)
- Lines 51–55: uv tool packages (pipenv, ruff, ralph-loop, gitsem, o2cfg)
- Lines 57–59: Upgrade exit logic (exit 1)
- Lines 62–66: Shell launch (`exec bash -l` or `exec bash -l -c "$*"`)

### opencode.json → Agent Configuration

| File | Blueprint Component |
| :--- | :--- |
| `opencode.json` | OpenCode agent config (formatter, LSP, snapshot, instructions) |

**Key settings:**
- `autoupdate: false` — Update notification disabled
- `formatter: true` — Enable formatting
- `lsp: true` — Enable language server protocol
- `share: "manual"` — Manual share mode
- `snapshot: true` — Enable snapshots
- `instructions: [".opencode/RULES.md", "AGENTS.md"]` — Rule file references

### Documentation Files

| File | Purpose |
| :--- | :--- |
| `README.md` | User-facing guide (build, run, upgrade, troubleshooting, security) |
| `AGENTS.md` | Agent workflow rules (blueprint → implementation → sync) |
| `.opencode/RULES.md` | Project-specific constraints (security, scoping, architecture, documentation) |

## Entry Points

| Context | Path | Description |
| :--- | :--- | :--- |
| Image build | `Containerfile` (root) | `podman build -t opencode:latest .` |
| Container PID 1 | `/container-init.sh` (inside image) | Init script invoked by tini |
| Default command | `opencode` (npm package) | OpenCode agent CLI (launched by init or CMD) |
| Interactive shell | `bash -l` (inside container) | Default when no argument given |
| Config | `opencode.json` (root) | OpenCode agent runtime configuration |
| Rules | `.opencode/RULES.md` | Project rules loaded by opencode.json |

## Build & Run Commands

### Build

```bash
podman build --no-cache -t opencode:latest .
```

With custom version:

```bash
podman build --no-cache --build-arg UV_VERSION=0.11.26 -t opencode:latest .
```

### Run (Interactive)

```bash
podman run --rm --userns=keep-id -ti \
  -v opencode:/home/opencode \
  -v "$PWD":/work \
  -v "$HOME"/.gitconfig:/home/opencode/.gitconfig \
  opencode:latest
```

### Run (Web Server)

```bash
podman run --rm --userns=keep-id -ti \
  -p 4096:4096 \
  -v opencode:/home/opencode \
  -v "$PWD":/work \
  -v "$HOME"/.gitconfig:/home/opencode/.gitconfig \
  opencode:latest opencode web --hostname 0.0.0.0
```

### Upgrade

```bash
podman run --rm --userns=keep-id -ti \
  -v opencode:/home/opencode \
  opencode:latest upgrade
```

## Language & Naming Conventions

| Convention | Rule |
| :--- | :--- |
| File / directory names | `kebab-case` (e.g., `container-init.sh`, `RULES.md`) |
| Shell scripts | `.sh` extension, `#!/bin/bash` shebang, `set -e` |
| Config files | JSON, professional English keys |
| Documentation | Professional English, plain language |
| Environment variables | `UPPER_SNAKE_CASE` |
| Git commits | Conventional Commits (`<type>(<scope>): <summary>`) |

## Dependency Registry

| Dependency | Type | Location | Version Source |
| :--- | :--- | :--- | :--- |
| `node:26` | Base image | Docker Hub | `26` tag |
| opencode-ai | npm package | `container-init.sh` line 25 | npm default |
| @biomejs/biome | npm package | `container-init.sh` line 26 | npm default |
| @playwright/cli | npm package (CLI) | `container-init.sh` line 31 | `@latest` |
| @playwright/mcp | npm package (MCP) | `opencode.json` | `@latest` |
| uv | pipx package | `container-init.sh` line 34 | `ENV UV_VERSION` (`0.11.26`) |
| pipenv | uv tool | `container-init.sh` line 51 | latest |
| ruff | uv tool | `container-init.sh` line 52 | latest |
| ralph-loop | uv tool (git) | `container-init.sh` line 53 | unpinned git URL |
| gitsem | uv tool (git) | `container-init.sh` line 54 | unpinned git URL |
| o2cfg | uv tool (git) | `container-init.sh` line 55 | unpinned git URL |
| tini | Init process | APT package | Debian stable repo |
| pipx | Python package installer | APT package | Debian stable repo |

## Volume Map

| Volume Name | Mount Point | Persistence | Contents |
| :--- | :--- | :--- | :--- |
| `opencode` (named) | `/home/opencode` | Yes | npm local packages, pipx binaries, configs |
| `$PWD` (bind) | `/work` | No | Host workspace directory |
| `~/.gitconfig` (bind) | `/home/opencode/.gitconfig` | No | Host Git identity |
