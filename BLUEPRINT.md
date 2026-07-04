# BLUEPRINT — Container for OpenCode

## System Goals

Provide an isolated, reproducible development environment for the OpenCode agent. The container:

- Runs on a minimal Debian base.
- Installs and persists a toolchain (Node/NVM, opencode-ai, Biome, uv, pipenv, ruff) on first start.
- Mounts a host directory into `/work` for live editing.
- Persists user data in a named volume at `/home/opencode`.
- Uses `tini` as PID 1 for proper signal forwarding and zombie reaping.

## Component Hierarchy

```
Container Image (debian:stable-slim)
├── Base OS Layer
│   ├── Debian stable-slim
│   └── APT packages (bash-completion, bc, ca-certificates, curl, file, gcc, git, gnupg, golang, govulncheck, iputils-ping, jq, less, libc6-dev, locales, lsof, man-db, nano, pipx, procps, ripgrep, rsync, shfmt, tini, tree, unzip, vim, xxd, zip)
├── Environment Configuration
│   ├── ENV variables (NVM_VERSION, UV_VERSION, PIPENV_VERSION, RUFF_VERSION, OPENCODE_VERSION, BIOME_VERSION, DEBIAN_FRONTEND, LANG, LC_ALL, HOME, PATH, NVM_DIR, TERM, EDITOR, CGO_ENABLED)
│   ├── Locale setup (nb_NO.UTF-8, en_US.UTF-8)
│   └── Shell niceties (bash-completion, aliases)
├── Runtime Installer (`container-init.sh`)
│   ├── Skeleton copy (/etc/skel → /home/opencode)
│   ├── NVM installation & Node LTS
│   ├── npm global packages (opencode-ai, @biomejs/biome)
│   ├── pipx packages (uv, pipenv, ruff)
│   └── Shell launch (exec bash -l or exec bash -l -c "$*")
└── Entrypoint / CMD
    ├── ENTRYPOINT: tini → container-init.sh
    └── CMD: opencode (default shell if no argument)
```

## Data Flow

```
Host Build Command
    │
    ▼
Containerfile (multi-step image build)
    │
    ├── APT layer (static, cached)
    ├── Locale layer (static)
    ├── Shell config layer (static)
    └── Init script baked into image (/container-init.sh)
    │
    ▼
Podman Run
    │
    ├── Named volume: opencode → /home/opencode (persists across runs)
    ├── Bind mount: $PWD → /work (host workspace)
    ├── Optional bind mount: ~/.gitconfig → /home/opencode/.gitconfig
    └── Optional ENV: OPENCODE_ENABLE_EXA=1
    │
    ▼
container-init.sh (PID 1 via tini)
    │
    ├── Check $1 for "upgrade"
    ├── Copy skeleton files
    ├── Install NVM (if missing)
    ├── Install Node LTS (if missing)
    ├── Install npm packages (if missing or upgrade)
    ├── Install pipx packages (if missing or upgrade)
    └── exec bash -l | exec bash -l -c "$*"
```

## State Management

### Persistent State (Named Volume: `/home/opencode`)

| Path | Purpose |
| :--- | :--- |
| `/home/opencode/.local/lib/nvm` | NVM installation |
| `/home/opencode/.nvm` | NVM metadata |
| `/home/opencode/.npm` | npm cache / global packages |
| `/home/opencode/.local/bin` | pipx binaries |
| `/home/opencode/.config` | Application configs |

### Ephemeral State (Discarded on container stop)

| Path | Purpose |
| :--- | :--- |
| `/work` | Host-mounted workspace (not persisted by the container) |
| `/tmp` | Temporary files |

### Upgrade Mode

When `$1 == "upgrade"`, the init script forces reinstallation of all managed packages and exits with status code 1. This signals the caller that an upgrade was performed and prevents the shell from launching.

## Contracts

### Entrypoint

```
ENTRYPOINT ["/usr/bin/tini", "--", "/container-init.sh"]
CMD ["opencode"]
```

### Build-Time Variables (ENV in Containerfile)

| Variable | Default | Role |
| :--- | :--- | :--- |
| `NVM_VERSION` | `v0.40.4` | NVM release tag |
| `UV_VERSION` | `0.11.7` | uv version constraint |
| `PIPENV_VERSION` | `2026.5.2` | pipenv version constraint |
| `RUFF_VERSION` | `0.15.11` | ruff version constraint |
| `OPENCODE_VERSION` | `latest` | opencode-ai npm tag |
| `BIOME_VERSION` | `latest` | @biomejs/biome npm tag |
| `OPENCODE_ENABLE_EXA` | *(unset)* | Enable Exa web tools at runtime |

### Runtime Arguments

| Argument | Effect |
| :--- | :--- |
| *(none / default)* | Interactive shell (`exec bash -l`) |
| `upgrade` | Force-reinstall all packages, then exit 1 |
| `<command>` | Execute command inside login shell (`exec bash -l -c "<command>"`) |

### Volume Mounts

| Container Path | Host Source | Persistence |
| :--- | :--- | :--- |
| `/home/opencode` | Named volume `opencode` | Yes (across runs) |
| `/work` | `$PWD` (bind mount) | No (host-driven) |
| `/home/opencode/.gitconfig` | `~/.gitconfig` (bind mount) | No (host file) |

## Persistence

- **Named volume** `opencode` at `/home/opencode` stores all installed toolchain state.
- **Bind mount** `$PWD:/work` provides the live workspace.
- No database or external service dependencies.
- Locale data is generated at build time and baked into the image.

## External Dependencies

| Dependency | Source | Purpose |
| :--- | :--- | :--- |
| `debian:stable-slim` | Docker Hub | Base OS image |
| `nvm-sh/nvm` (GitHub) | `https://github.com/nvm-sh/nvm` | Node version manager |
| `opencode-ai` | npm | OpenCode agent CLI |
| `@biomejs/biome` | npm | Fast formatter/linter |
| `uv` | PyPI (via pipx) | Python package manager |
| `pipenv` | PyPI (via pipx) | Python dependency manager |
| `ruff` | PyPI (via pipx) | Python linter/formatter |

## Error Boundaries

- `set -e` in `container-init.sh` aborts the init on any command failure.
- Each package installation uses a conditional check (`which` / `npm list`) to avoid redundant installs.
- Upgrade mode exits with code 1 to distinguish from normal operation.
- `tini` handles SIGINT/SIGTERM forwarding; no custom signal traps needed.

## Security Model

- Rootless Podman with `--userns=keep-id` maps container UID to host UID.
- Dependencies are isolated in the container; no global host modifications.
- Host directory mounts are advisory — users may add `:ro` for read-only workspace mounts.
- Sensitive state (git credentials) is managed via explicit bind mounts or environment variables.
