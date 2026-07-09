#!/bin/bash
set -e

# Allow upgrade
if [[ "${1,,}" == "upgrade" ]]; then
	UPGRADE=true
else
	UPGRADE=false
fi

# Install skeleton
rsync -ur /etc/skel/ /home/opencode/

# Install NVM
if [[ ! -d "$NVM_DIR" ]]; then
	mkdir -p "$NVM_DIR"
	curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | PROFILE=$HOME/.profile bash
fi

# Source NVM
source "$NVM_DIR/nvm.sh"

# Install Node
if ! command -v node &>/dev/null || [[ "$UPGRADE" == "true" ]]; then
	nvm install --lts
fi

# Minimum age set to one week
npm config set min-release-age 7 --location=user

# Install node packages
install_npm_package() {
	if ! npm list -g "$1" &>/dev/null || [[ "$UPGRADE" == "true" ]]; then
		echo "[init] Installing $1..."
		npm i -g "$1"
	fi
}

install_npm_package opencode-ai
install_npm_package "@biomejs/biome"

# Install PIP packages
PATH=$PATH:$HOME/.local/bin

# Install uv via pipx first (required for uv tool install)
if ! command -v uv &>/dev/null || [[ "${1,,}" == "upgrade" ]]; then
	echo "[init] Installing uv..."
	pipx install --force -qq "uv~=$UV_VERSION"
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
