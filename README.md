# Container for OpenCode

**Run the OpenCode agent in an isolated, safer environment using Podman.**

## Introduction
This repository provides a container setup for running OpenCode in a relaxed, "safe-vibe" development environment. It ensures a reproducible workspace while protecting your host system and keeping dependencies isolated.

The image is based on `node:26` for a minimal footprint. Developer tools (opencode-ai, Biome, playwright-cli, uv, pipenv, ruff, ralph-loop, gitsem, o2cfg) are installed at first container start and persisted in the `/home/opencode` named volume, so subsequent starts are fast.

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
OC="alias oc='podman run --hostname vibe --name opencode --rm --userns=keep-id -ti --shm-size=2gb -v opencode:/home/opencode -v \"\$PWD\":/work -v \"\$HOME\"/.gitconfig:/home/opencode/.gitconfig opencode:latest'"
OCW="alias ocw='podman run --hostname vibe --name opencode --rm --userns=keep-id -ti --shm-size=2gb -p 4096:4096 -v opencode:/home/opencode -v \"\$PWD\":/work -v \"\$HOME\"/.gitconfig:/home/opencode/.gitconfig opencode:latest opencode web --hostname 0.0.0.0'"
grep -q "^alias oc=" ~/.bashrc && sed -i "s|^alias oc=.*|$OC|" ~/.bashrc || echo "$OC" >> ~/.bashrc
grep -q "^alias ocw=" ~/.bashrc && sed -i "s|^alias ocw=.*|$OCW|" ~/.bashrc || echo "$OCW" >> ~/.bashrc
source ~/.bashrc
```

### Upgrading software

Pass `upgrade` as the first argument to force-reinstall all managed packages (opencode-ai, Biome, playwright-cli, uv, pipenv, ruff, ralph-loop, gitsem, o2cfg). The container exits after the upgrade is complete.

```bash
podman run --rm --userns=keep-id -ti \
  -v opencode:/home/opencode \
  opencode:latest upgrade
```

If you have the `oc` alias set up:

```bash
oc upgrade
```

> **Note:** The upgrade run exits with a non-zero status code by design. This distinguishes an upgrade invocation from a normal interactive session and prevents accidentally continuing into a shell after the upgrade.

### Browser Automation (playwright-cli)

playwright-cli is a command-line tool for browser automation, pre-installed in this container. It lets the opencode agent interact with web pages programmatically.

#### Installing additional browsers

Chromium is installed by default. To install other browsers:

```bash
playwright-cli install-browser firefox
playwright-cli install-browser webkit
playwright-cli install-browser msedge
```

#### Using with opencode

Simply ask the agent to perform browser tasks—it will use playwright-cli automatically.

### Flag Reference
| Flag | Description |
| :--- | :--- |
| `--rm` | Remove the container automatically when it exits. |
| `--userns=keep-id` | Map the container user to your host user (keeps file ownership sane). |
| `-ti` | Allocate a TTY and run an interactive terminal session. |
| `-v opencode:/home...` | Persist OpenCode home data in a named volume between sessions. |
| `-v "$PWD":/work` | Mount current directory to `/work` so edits are visible on the host. |
| `-v .../.gitconfig` | Share host git configuration (identity/settings) with the container. |

### Signal Handling (CTRL+C)
`tini` is installed in the image and set as `ENTRYPOINT` PID 1. It properly reaps zombie processes and forwards `SIGINT`/`SIGTERM` to child processes, so **CTRL+C works in both interactive TUI mode and headless web-server mode** without any extra runtime flags.

If you prefer to use the runtime-injected init (equivalent behaviour, no image rebuild required), pass `--init` to `podman run` — but this is redundant when using this image since `tini` is already baked in.

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
