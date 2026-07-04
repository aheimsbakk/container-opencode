# CODEBASE — Container for OpenCode

## Target Stack

| Aspect | Choice |
| :--- | :--- |
| Base OS | Debian stable-slim |
| Container Runtime | Podman (rootless) |
| Init Process | tini (PID 1) |
| Shell | Bash (login shell) |
| Node Manager | NVM |
| Python Package Mgr | pipx (uv, pipenv, ruff) |
| npm Packages | opencode-ai, @biomejs/biome |
| Config Format | JSON (opencode.json) |

## Directory Tree

```
.
├── AGENTS.md                        # Master rules and workflow for AI agents
├── BLUEPRINT.md                     # Language-agnostic architecture specification
├── CODEBASE.md                      # This file — concrete file-to-component mapping
├── Containerfile                    # Image build definition
├── container-init.sh                # Runtime initialization script (entrypoint)
├── opencode.json                    # OpenCode agent configuration
├── README.md                        # User-facing documentation
└── .opencode/
    └── RULES.md                     # Project-specific rules (referenced by opencode.json)
```

## Physical Path Mappings

### Containerfile → Image Build Layer

| File | Blueprint Component |
| :--- | :--- |
| `Containerfile` | Base OS Layer, Environment Configuration, Entrypoint/CMD |

**Key sections:**
- `FROM debian:stable-slim` → Base OS
- `ENV` declarations → Build-time variables
- `RUN apt-get install ...` → APT packages
- `RUN locale-gen` → Locale setup
- `RUN ... /etc/bash.bashrc` → Shell niceties
- `ADD container-init.sh /` → Init script baked into image
- `WORKDIR /work` → Working directory
- `VOLUME ["/work", "/home/opencode"]` → Volume declarations
- `ENTRYPOINT` / `CMD` → Entrypoint contract

### container-init.sh → Runtime Installer

| File | Blueprint Component |
| :--- | :--- |
| `container-init.sh` | Runtime Installer (NVM, Node, npm, pipx, shell launch) |

**Key logic blocks:**
- Lines 1–10: Upgrade flag detection (`$1 == "upgrade"`)
- Line 13: Skeleton copy (`rsync /etc/skel → /home/opencode`)
- Lines 16–20: NVM installation
- Lines 23–26: NVM sourcing + Node LTS install
- Lines 29–30: npm global packages (conditional install)
- Lines 33–37: pipx packages (uv, pipenv, ruff — conditional install)
- Lines 39–42: Upgrade exit logic (exit 1)
- Lines 45–48: Shell launch (`exec bash -l` or `exec bash -l -c "$*"`)

### opencode.json → Agent Configuration

| File | Blueprint Component |
| :--- | :--- |
| `opencode.json` | OpenCode agent config (formatter, LSP, snapshot, instructions) |

**Key settings:**
- `autoupdate: "notify"` — Update notification behavior
- `formatter: true` — Enable formatting
- `lsp: true` — Enable language server protocol
- `share: "manual"` — Manual share mode
- `snapshot: true` — Enable snapshots
- `instructions: [".opencode/RULES.md"]` — Rule file reference

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
podman build --no-cache --build-arg OPENCODE_VERSION=0.3.1 -t opencode:latest .
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
| `debian:stable-slim` | Base image | Docker Hub | `stable-slim` tag |
| NVM | Node version manager | `ENV NVM_VERSION` in Containerfile | `v0.40.4` |
| opencode-ai | npm package | `container-init.sh` line 29 | `ENV OPENCODE_VERSION` |
| @biomejs/biome | npm package | `container-init.sh` line 30 | `ENV BIOME_VERSION` |
| uv | pipx package | `container-init.sh` line 35 | `ENV UV_VERSION` |
| pipenv | pipx package | `container-init.sh` line 36 | `ENV PIPENV_VERSION` |
| ruff | pipx package | `container-init.sh` line 37 | `ENV RUFF_VERSION` |
| tini | Init process | APT package | Debian stable repo |
| pipx | Python package installer | APT package | Debian stable repo |

## Volume Map

| Volume Name | Mount Point | Persistence | Contents |
| :--- | :--- | :--- | :--- |
| `opencode` (named) | `/home/opencode` | Yes | NVM, Node, npm cache, pipx binaries, configs |
| `$PWD` (bind) | `/work` | No | Host workspace directory |
| `~/.gitconfig` (bind) | `/home/opencode/.gitconfig` | No | Host Git identity |
