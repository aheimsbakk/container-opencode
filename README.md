# Container for OpenCode

**Run the OpenCode agent in an isolated, safer environment using Podman.**

## Introduction
This repository provides a container setup for running OpenCode in a relaxed, "safe-vibe" development environment. It ensures a reproducible workspace while protecting your host system and keeping dependencies isolated.

The image is based on `node:26` for a minimal footprint. Developer tools (@opencode/cli, Biome, playwright-cli, uv, pipenv, ruff, ralph-loop, gitsem, o2cfg) are installed at first container start and persisted in the `/home/opencode` named volume, so subsequent starts are fast.

## Prerequisites
- Podman (rootless recommended). Minimum tested: Podman 4.x.
- A POSIX shell (bash, zsh).
- Optional: a ~/.gitconfig file if you plan to share Git identity with the container.

## Quickstart

Build the image:

```bash
podman build --no-cache -t opencode:latest .
```

`UV_VERSION` is pinned via an `ENV` variable in the `Containerfile` and can be overridden at build time with `--build-arg`:

```bash
podman build --no-cache --build-arg UV_VERSION=0.11.26 -t opencode:latest .
```

### Build-arg / ENV Reference
| Variable | Default | Description |
| :--- | :--- | :--- |
| `UV_VERSION` | `0.11.26` | pipx version constraint for `uv`. |

If you want to enable Exa web tools at runtime, add `-e OPENCODE_ENABLE_EXA=1` to your `podman run` command.

## Usage

Run directly (interactive):

```bash
podman run --rm --userns=keep-id -ti --shm-size=2gb \
  -v opencode:/home/opencode \
  -v "$PWD":/work \
  -v "$HOME"/.gitconfig:/home/opencode/.gitconfig \
  opencode:latest
```

With Exa enabled:

```bash
podman run --rm --userns=keep-id -ti --shm-size=2gb \
  -e OPENCODE_ENABLE_EXA=1 \
  -v opencode:/home/opencode \
  -v "$PWD":/work \
  -v "$HOME"/.gitconfig:/home/opencode/.gitconfig \
  opencode:latest
```

Setup aliases (replace if changed)

```bash
OC="alias oc='podman run --hostname vibe --name opencode --rm --userns=keep-id -ti --shm-size=2gb -v opencode:/home/opencode:z -v \"\$PWD\":/work:z -v \"\$HOME\"/.gitconfig:/home/opencode/.gitconfig:ro,z opencode:latest'"
OCW="alias ocw='podman run --hostname vibe --name opencode --rm --userns=keep-id -ti --shm-size=2gb -p 4096:4096 -v opencode:/home/opencode:z -v \"\$PWD\":/work:z -v \"\$HOME\"/.gitconfig:/home/opencode/.gitconfig:ro,z opencode:latest opencode2 serve --hostname 0.0.0.0'"
OCL="alias ocl='podman run --hostname vibe --name opencode --rm --userns=keep-id -ti --shm-size=2gb -v opencode:/home/opencode:z -v \"\$PWD\":/work:z -v \"\$HOME\"/.gitconfig:/home/opencode/.gitconfig:ro,z -e LIBVIRT_DEFAULT_URI=qemu+ssh://\$USER@host.containers.internal/session opencode:latest'"
grep -q "^alias oc=" ~/.bashrc && sed -i.bak "s|^alias oc=.*|$OC|" ~/.bashrc || echo "$OC" >> ~/.bashrc
grep -q "^alias ocw=" ~/.bashrc && sed -i.bak "s|^alias ocw=.*|$OCW|" ~/.bashrc || echo "$OCW" >> ~/.bashrc
grep -q "^alias ocl=" ~/.bashrc && sed -i.bak "s|^alias ocl=.*|$OCL|" ~/.bashrc || echo "$OCL" >> ~/.bashrc
rm -f ~/.bashrc.bak
source ~/.bashrc
```

### Flag Reference
| Flag | Description |
| :--- | :--- |
| `--rm` | Remove the container automatically when it exits. |
| `--userns=keep-id` | Map the container user to your host user (keeps file ownership sane). |
| `-ti` | Allocate a TTY and run an interactive terminal session. |
| `--hostname vibe` | Sets the container hostname to `vibe`. |
| `--name opencode` | Assigns the name `opencode` to the container instance. |
| `--shm-size=2gb` | Increases shared memory size (required for stable browser automation). |
| `-p 4096:4096` | Maps host port 4096 to container port 4096 (used for `opencode2 serve` mode). |
| `-v opencode:/home...` | Persist OpenCode home data in a named volume between sessions. |
| `-v "$PWD":/work` | Mount current directory to `/work` so edits are visible on the host. |
| `-v .../.gitconfig` | Share host git configuration (identity/settings) with the container. |
| `-e OPENCODE_ENABLE_EXA=1` | Enables Exa web search tools within the container. |
| `-e LIBVIRT_DEFAULT_URI=...` | Default libvirt URI for `virsh`; `ocl` points it at the host session daemon over SSH. |

### Shared libvirt session

Give the container access to your user libvirt session (`qemu:///session`) over SSH. The `ocl` alias sets `LIBVIRT_DEFAULT_URI`, so `virsh` inside the container reaches the host session daemon without a `-c` argument.

**Prerequisites:**

- `virsh` on the host (`libvirt-clients` on Debian/Ubuntu).
- An SSH server on the host, reachable from the container as `host.containers.internal` on port 22.
- A key pair in `/home/opencode/.ssh` inside the container, with the public key in `~/.ssh/authorized_keys` on the host. libvirt runs `ssh` with `BatchMode=yes`, so password prompts and passphrases cannot be answered.
- A remote netcat with Unix-socket support (`nc -U`) on the host — `netcat-openbsd` on Debian/Ubuntu, `nmap-ncat` on Fedora. libvirt tunnels the libvirt socket through `ssh host nc -U <socket>`.
- `virt-ssh-helper` on the host, if you restrict the key to libvirt traffic (step 2) — shipped by `libvirt-daemon-common` on Fedora, Debian, and Ubuntu.

1. In the container, create a key (persisted in the `opencode` volume):

   ```bash
   ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
   cat ~/.ssh/id_ed25519.pub
   ```

2. From a host terminal, append the printed key to `~/.ssh/authorized_keys` for the host user that runs `podman` (the alias passes the host's `$USER`). Restrict the key to libvirt traffic by adding options before the key type. On Fedora the line looks like this (key body replaced with a placeholder):

   ```text
   restrict,command="/usr/bin/virt-ssh-helper qemu:///session" ssh-ed25519 AAAA...<key from step 1>
   ```

   `command=` forces every connection with this key to run libvirt's socket proxy against `qemu:///session`, whatever the container asks for. `restrict` blocks the pseudo-terminal, agent, and port forwarding. Without these options, the key grants a full shell on the host. Confirm the helper path on your host with `command -v virt-ssh-helper` before pasting the line.

3. Verify the setup from inside the container. Because the forced command replaces any requested command, plain `ssh <host-user>@host.containers.internal` no longer opens a shell — that is the intended restriction. Test through libvirt instead:

   ```bash
   virsh list --all
   ```

The SSH connection starts the host session daemon on demand, so no host `virsh` session has to stay open. The alias expands `$USER` in the host shell, so it follows the account that runs `podman`; override the URI if your SSH login name differs.

> **Warning:** The container can create, start, stop, and delete your user session VMs and read their disk images. Use `oc` when you do not need this access.

**Bridged networking:** session mode cannot create bridges, so it uses user-mode (slirp) networking unless an existing bridge is allowed. To attach a VM to a host bridge, whitelist it for QEMU's setuid helper on the host:

```bash
echo 'allow virbr0' | sudo tee /etc/qemu/bridge.conf
sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper   # /usr/libexec/qemu-bridge-helper on Fedora
```

Fedora ships the helper setuid with `allow virbr0` already in place. Debian and Ubuntu ship the helper in `qemu-system-common` without the setuid bit and without `/etc/qemu/bridge.conf`, so both lines above are needed there.

### Upgrading software

Pass `upgrade` as the first argument to force-reinstall all managed packages (@opencode/cli, Biome, playwright-cli, uv, pipenv, ruff, ralph-loop, gitsem, o2cfg). The container exits after the upgrade is complete.

```bash
podman run --rm --userns=keep-id -ti \
  -v opencode:/home/opencode \
  opencode:latest upgrade
```

If you have the `oc` alias set up:

```bash
oc upgrade
```

> **Important:** Only versions older than 7D will be installed. Minimum release age is configured both for `npm` and `uv`.

> **Note:** The upgrade run exits with a non-zero status code by design. This distinguishes an upgrade invocation from a normal interactive session and prevents accidentally continuing into a shell after the upgrade.

### Signal Handling (CTRL+C)
`tini` is installed in the image and set as `ENTRYPOINT` PID 1. It properly reaps zombie processes and forwards `SIGINT`/`SIGTERM` to child processes, so **CTRL+C works in both interactive TUI mode and headless web-server mode** without any extra runtime flags.

If you prefer to use the runtime-injected init (equivalent behaviour, no image rebuild required), pass `--init` to `podman run` — but this is redundant when using this image since `tini` is already baked in.

## Installed software

### Web Toolchain ([Biome](https://github.com/biomejs/biome))
Fast linter and formatter for web projects (JavaScript, TypeScript, JSON, etc.).

### Browser Automation ([playwright-cli](https://github.com/microsoft/playwright-cli))
CLI for browser automation, optimized for coding agents to interact with web pages via a token-efficient, skill-based interface.

#### Installing additional browsers
Chromium is installed by default. To install other browsers:

```bash
playwright-cli install-browser firefox
playwright-cli install-browser webkit
playwright-cli install-browser msedge
```

#### Using with opencode
Simply ask the agent to perform browser tasks—it will use `playwright-cli` automatically.

### Python Package Management
* **[uv](https://github.com/astral-sh/uv)**: Extremely fast Python package and project manager.
* **[pipenv](https://github.com/pypa/pipenv)**: Tool for managing Python dependencies and virtual environments.

### Python Linting & Formatting ([Ruff](https://github.com/astral-sh/ruff))
Extremely fast Python linter and code formatter.

### AI Iteration Loop ([ralph-loop](https://github.com/aheimsbakk/ralph-loop))
A utility to loop commands until they signal completion via a "promise" (e.g., `<promise>DONE</promise>`), enabling autonomous AI agent iterations.

### Git Versioning ([gitsem](https://github.com/aheimsbakk/gitsem))
Command-line utility for managing semantically versioned (SemVer) Git tags.

### OpenCode Configuration ([o2cfg](https://github.com/aheimsbakk/o2cfg))
Generates OpenCode provider configurations by auto-discovering models from OpenAI-compatible APIs.

### CAD and Headless Display (OpenSCAD, xauth, Xvfb)
* **OpenSCAD**: 3D modeling application for programmable CAD models.
* **xauth**: X server authentication utility.
* **Xvfb**: virtual X server, so GUI and browser workloads run headless inside the container.

These are baked into the image at build time (APT packages), not installed at first start.

### CLI Productivity and Debugging Tools
* **bat**: file viewer with syntax highlighting, aliased from `batcat`.
* **fd**: fast file finder, aliased from `fd-find`.
* **entr**: reruns a command when files change.
* **parallel**: runs commands in parallel across inputs.
* **shellcheck**: linter for shell scripts.
* **sqlite3**: command-line shell for SQLite databases.
* **strace**: traces system calls and signals of a process.
* **iproute2**: network tooling (`ip`, `ss`).
* **dnsutils**: DNS lookup tools (`dig`, `nslookup`).
* **netcat-traditional**: read and write across network connections.
* **yq**: query and convert YAML, JSON, and other formats (jq-style syntax).

These are baked into the image at build time (APT packages), not installed at first start.

## Troubleshooting
- If Podman is not found, install Podman for your distribution or use Docker as an alternative (adjust flags). 
- Permission errors when mounting: ensure rootless Podman is configured, or run with appropriate privileges. Avoid running containers as root unless necessary.
- If ~/.gitconfig is missing, the -v "$HOME"/.gitconfig mount will fail; either create a gitconfig or remove that mount.
- Port conflicts for 4096: choose a different host port (`-p HOST:4096`) when running ocw.

## Security Notes
- Containers reduce risk but are not a full security guarantee. Avoid running untrusted code without extra precautions.
- Be cautious when mounting host directories ("-v $PWD:/work"); this gives the container access to those files. Consider read-only mounts when appropriate: `-v "$PWD":/work:ro`.
- Sharing ~/.gitconfig exposes your git identity; prefer explicit environment variables for credentials and identity where possible.
- For stricter isolation consider SELinux, seccomp, user namespaces, or running inside a dedicated VM.
