#!/bin/bash
set -e

# NVM verison to use for installing NPM latest
export NVM_VERSION="v0.40.4"

# Python MCP server library
export MCP_VERSION=1.26

# Enable websearch
export OPENCODE_ENABLE_EXA=1

# Ensure HOME is writable; warn if it is not.
# This is a best-effort check and may fail if the container runs as a non-root user.
if [ ! -w "$HOME" ]; then
    echo "WARNING: $HOME is not writable. Exiting."
    exit 1
fi

# Copy default skel files into the user's home without overwriting newer files.
rsync -ur /etc/skel/. "$HOME"/

# Download and install NVM, and fetch NPM LTS
if [ ! -d "$HOME/.nvm" ]; then
    echo "=== Downloading NVM ${NVM_VERSION}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | PROFILE="${HOME}/.bashrc" bash

    echo "=== Loading NVM"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    echo "=== Install NPM LTS"
    nvm install --lts
    nvm use --lts
fi

# Installer siste versjon av UV
test -f $HOME/.local/bin/uv || curl -LsSf https://astral.sh/uv/install.sh | sh

# Instal Python MCP library if we find .mcp
test -f .mcp && PIPENV_VENV_IN_PROJECT=1 pipenv install mcp~=${MCP_VERSION}

# Default TMUX config
test -f $HOME/.tmux.conf || cat <<EOF > $HOME/.tmux.conf
set-option -g default-shell /bin/bash
set -g mouse on
bind -n C-s set-window-option synchronize-panes
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*:Tc"
set -ga terminal-overrides ",*:RGB"
EOF

# If the first argument starts with a dash (e.g. -c), treat it as an option for bash
# and prepend /bin/bash so options are passed to the shell.
if [ "${1#-}" != "$1" ]; then
    set -- /bin/bash "$@"
fi

# Create a minimal .gitconfig with a safe.directory entry if it doesn't already exist.
if [ ! -f "$HOME/.gitconfig" ]; then
    cat <<EOF > "$HOME/.gitconfig"
[safe]
    directory = /work
EOF
fi

# Execute the supplied command (defaults to a shell when no explicit command is given).
exec "$@"
