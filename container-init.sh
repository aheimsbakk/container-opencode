#!/bin/bash
set -e

# Allow upgrade
if [[ "${1,,}" == "upgrade" ]]; then
	UPGRADE=true
else
	UPGRADE=false
fi

# Ensure path
PATH=$HOME/.local/bin:$HOME/node_modules/.bin:$PATH

# Install skeleton
rsync -ur /etc/skel/ /home/opencode/

# Minimum age set to one week
npm config set min-release-age 7 --location=user

# Install node packages
install_npm_package() {
	cd $HOME
	if ! npm list "$1" &>/dev/null || [[ "$UPGRADE" == "true" ]]; then
		echo "[init] Installing $1..."
		npm i "$1"
	fi
	cd /work
}

install_npm_package opencode-ai
install_npm_package "@biomejs/biome"
install_npm_package "@playwright/cli@latest"

# Set PATH to node modules
grep -q node_modules /home/opencode/.profile || echo 'PATH=$HOME/node_modules/.bin:$PATH' >> /home/opencode/.profile

# Install uv via pipx first (required for uv tool install)
if ! command -v uv &>/dev/null || [[ "${1,,}" == "upgrade" ]]; then
	echo "[init] Installing uv..."
	pipx install --force "uv~=$UV_VERSION"
fi

# Install uv tool packages
_UPGRADE="${1,,}"
install_uv_tool() {
	if ! command -v "$1" &>/dev/null || [[ "$_UPGRADE" == "upgrade" ]]; then
		echo "[init] Installing $1..."
		uv tool install --exclude-newer "1 week" "${2:-$1}"
	fi
}

install_uv_tool pipenv
install_uv_tool ruff
install_uv_tool ralph-loop "git+https://github.com/aheimsbakk/ralph-loop"
install_uv_tool gitsem "git+https://github.com/aheimsbakk/gitsem"
install_uv_tool o2cfg "git+https://github.com/aheimsbakk/o2cfg"

if [[ "${1,,}" == "upgrade" ]]; then
	exit 1
fi

# Start
if [ $# -eq 0 ]; then
	exec bash -l
else
	exec bash -l -c "$*"
fi
