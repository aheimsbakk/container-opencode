
# Container for OpenCode

Run the OpenCode agent in an isolated, safer environment using Podman.

## Introduction

This repository provides a container setup for running OpenCode in a relaxed, "safe-vibe" development environment. Running inside a container helps protect your host system, keeps dependencies isolated, and gives you a reproducible workspace.

If you're not familiar with containers or basic security: think of a container as a lightweight sandbox. It creates a separate workspace for programs so they cannot change most of your main system unless you explicitly share files or ports. That reduces the chance of accidental damage and makes cleanup simple.

Key benefits:
- Isolation: the container limits what the agent can access on your host machine.
- Reproducibility: the same container image creates a consistent environment for everyone.
- Safer defaults: this setup runs the container as your user and only exposes folders you explicitly mount.

## Build

Build the container image with Podman:

```bash
podman build -t opencode:latest .
```

## Usage

Start the container with this command:

```bash
podman run --rm --userns=keep-id -ti -v opencode:/home/opencode -v $PWD:/work opencode:latest
```

Quick reference for the flags:
- `--rm`: remove the container when it exits.
- `-ti`: run an interactive terminal session.
- `-u $UID`: run as your current user so files created in the container have correct ownership on the host.
- `-v opencode:/home/opencode`: use a named volume to persist OpenCode home data between sessions.
- `-v $PWD:/work`: mount your current directory into the container at `/work` so you can edit files from the host.

## Security notes

- Containers reduce risk but are not a full security guarantee — avoid running untrusted code without additional precautions.
- Only the directories you mount are directly accessible to the container; do not mount sensitive host paths unless necessary.
- For stricter isolation consider extra Podman options (user namespaces, SELinux, seccomp) or run inside a dedicated VM.
