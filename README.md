
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
podman run --rm --userns=keep-id -ti -v opencode:/home/opencode -v $PWD:/work -v $HOME/.gitconfig:/home/opencode/.gitconfig opencode:latest
```

If you start the container often, add a small shell alias to your `~/.bashrc` or `~/.profile` so you don't have to remember the full command. For example:

- Add to alias to `~/.bashrc`
  ```bash
  cat <<EOF >> ~/.bashrc
  alias oc='podman run --rm --userns=keep-id -ti -v opencode:/home/opencode -v "\$PWD":/work -v "\$HOME"/.gitconfig:/home/opencode/.gitconfig opencode:latest'
  EOF
  ```
- Then reload your shell or run
  ```bash
  source ~/.bashrc
  ```

### Quick reference for the flags

- `--rm`: remove the container when it exits.
- `-ti`: run an interactive terminal session.
- `-v opencode:/home/opencode`: use a named volume to persist OpenCode home data between sessions.
- `-v $PWD:/work`: mount your current directory into the container at `/work` so you can edit files from the host.
Quick reference for the flags used in the example and alias:
- `--rm`: remove the container when it exits.
- `--userns=keep-id`: map the container user to your host user (keeps file ownership sane).
- `-ti`: allocate a TTY and run an interactive terminal session.
- `-v opencode:/home/opencode`: use a named volume to persist OpenCode home data between sessions.
- `-v "$PWD":/work`: mount your current directory into the container at `/work` so edits are visible on the host. The alias uses the same `$PWD` mount.
- `-v "$HOME"/.gitconfig:/home/opencode/.gitconfig`: share your host git configuration into the container so git identity and settings are preserved.

## Security notes

- Containers reduce risk but are not a full security guarantee — avoid running untrusted code without additional precautions.
- Only the directories you mount are directly accessible to the container; do not mount sensitive host paths unless necessary.
- For stricter isolation consider extra Podman options (user namespaces, SELinux, seccomp) or run inside a dedicated VM.
