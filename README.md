# Container for OpenCode

**Run the OpenCode agent in an isolated, safer environment using Podman.**

## Introduction
This repository provides a container setup for running OpenCode in a relaxed, "safe-vibe" development environment. It ensures a reproducible workspace while protecting your host system and keeping dependencies isolated.

## Build
```bash
podman build --no-cache -t opencode:latest .
```

## Usage
**Run directly:**
```bash
podman run --rm --userns=keep-id -ti \
  -v opencode:/home/opencode \
  -v "$PWD":/work \
  -v "$HOME"/.gitconfig:/home/opencode/.gitconfig \
  opencode:latest
```

**Setup Alias (Recommended):**
Add a shorthand `oc` command to your shell profile to avoid typing the full command:

```bash
# Add to ~/.bashrc or ~/.profile
cat <<EOF >> ~/.bashrc
alias oc='podman run --hostname vibe --rm --userns=keep-id -ti -v opencode:/home/opencode -v "\$PWD":/work -v "\$HOME"/.gitconfig:/home/opencode/.gitconfig opencode:latest'
EOF

Add a shorthand `ocw` for starting the OpenCode web on port 4096:

```bash
# Add to ~/.bashrc or ~/.profile
cat <<EOF >> ~/.bashrc
alias ocw='podman run --hostname vibe --rm --userns=keep-id -t -p 4096:4096 -v opencode:/home/opencode -v "$PWD":/work -v "$HOME"/.gitconfig:/home/opencode/.gitconfig opencode:latest opencode-cli web --hostname 0.0.0.0'
EOF

# Reload shell
source ~/.bashrc
```

### Flag Reference
| Flag | Description |
| :--- | :--- |
| `--rm` | Remove the container automatically when it exits. |
| `--userns=keep-id` | Map the container user to your host user (keeps file ownership sane). |
| `-ti` | Allocate a TTY and run an interactive terminal session. |
| `-v opencode:/home...` | Persist OpenCode home data in a named volume between sessions. |
| `-v "$PWD":/work` | Mount current directory to `/work` so edits are visible on the host. |
| `-v .../.gitconfig` | Share host git configuration (identity/settings) with the container. |

## Security Notes
* **Limitation:** Containers reduce risk but are not a full security guarantee. Avoid running untrusted code without extra precautions.
* **Access:** Only directories explicitly mounted are accessible to the agent.
* **Hardening:** For stricter isolation, consider using SELinux, seccomp, or running inside a dedicated VM.
