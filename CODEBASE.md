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
├── CONTRIBUTING.md                  # Developer guide (scripts, tooling, workflow)
├── Containerfile                    # Image build definition
├── container-init.sh                # Runtime initialization script (entrypoint)
├── opencode.json                    # OpenCode agent configuration
├── README.md                        # User-facing documentation
├── VERSION                          # Current version number
├── docs/
│   └── memory/
│       ├── INDEX.md                 # Memory skill index
│       └── archive/                 # Memory entries (decision log)
├── scripts/
│   ├── bump-version.sh              # Version increment helper
│   ├── validate-changelog.sh        # VERSION/CHANGELOG consistency check
│   └── verify_codebase_sync.sh      # CODEBASE.md path and line-reference verification
└── .opencode/
    ├── RULES.md                     # Project-specific rules (referenced by opencode.json)
    ├── agents/                      # OpenCode agent definitions
    └── skills/                      # OpenCode skills (clear-language, memory, todo-txt, wrap-up)
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
- Lines 4–9: Upgrade flag detection (`UPGRADE=true`)
- Line 12: PATH prepended with `$HOME/.local/bin` and `$HOME/node_modules/.bin`
- Line 15: Skeleton copy (`rsync -ur /etc/skel/`)
- Line 21: npm config (`min-release-age 7 --location=user`)
- Lines 24–29: `install_npm_package` helper function (local install, cd to $HOME, cd /work)
- Lines 31–33: npm local packages (`opencode-ai`, `@biomejs/biome`, `@playwright/cli@latest`)
- Lines 35–36: playwright-cli skill install (`playwright-cli install --skills`)
- Line 39: Append node_modules PATH to `.profile`
- Lines 41–45: uv installation via pipx (`pipx install --force`, conditional on upgrade or missing)
- Lines 47–54: `install_uv_tool` helper function (`_UPGRADE` variable, `--exclude-newer 1 week`)
- Lines 56–60: uv tool packages (`pipenv`, `ruff`, `ralph-loop`, `gitsem`, `o2cfg`)
- Lines 62–64: Upgrade exit logic (`exit 1`)
- Lines 70–74: Shell launch (`exec bash -l` or `exec bash -l -c "$*"`)

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
| `CONTRIBUTING.md` | Developer guide (scripts, tooling, workflow) |
| `CHANGELOG.md` | Version history with why/model/tags entries per release |
| `VERSION` | Current release number, validated against CHANGELOG.md |
| `AGENTS.md` | Agent workflow rules (blueprint → implementation → sync) |
| `.opencode/RULES.md` | Project-specific constraints (security, scoping, architecture, documentation) |
| `docs/memory/INDEX.md` | Memory skill index (entries under `docs/memory/archive/`) |

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
podman run --rm --userns=keep-id -ti --shm-size=2gb \
  -v opencode:/home/opencode \
  -v "$PWD":/work \
  -v "$HOME"/.gitconfig:/home/opencode/.gitconfig \
  opencode:latest
```

### Run (Web Server)

```bash
podman run --rm --userns=keep-id -ti --shm-size=2gb \
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
| opencode-ai | npm package | `container-init.sh` line 31 | npm default |
| @biomejs/biome | npm package | `container-init.sh` line 32 | npm default |
| @playwright/cli | npm package (CLI) | `container-init.sh` line 33 | `@latest` |
| @playwright/mcp | npm package (MCP) | `opencode.json` (commented out, disabled) | `@latest` |
| uv | pipx package | `container-init.sh` lines 42–44 (`pipx install --force`) | `ENV UV_VERSION` (`0.11.26`) |
| pipenv | uv tool | `container-init.sh` line 56 | latest |
| ruff | uv tool | `container-init.sh` line 57 | latest |
| ralph-loop | uv tool (git) | `container-init.sh` line 58 | unpinned git URL |
| gitsem | uv tool (git) | `container-init.sh` line 59 | unpinned git URL |
| o2cfg | uv tool (git) | `container-init.sh` line 60 | unpinned git URL |
| tini | Init process | APT package | Debian stable repo |
| pipx | Python package installer | APT package | Debian stable repo |

## Volume Map

| Volume Name | Mount Point | Persistence | Contents |
| :--- | :--- | :--- | :--- |
| `opencode` (named) | `/home/opencode` | Yes | npm local packages, pipx binaries, configs |
| `$PWD` (bind) | `/work` | No | Host workspace directory |
| `~/.gitconfig` (bind) | `/home/opencode/.gitconfig` | No | Host Git identity |
