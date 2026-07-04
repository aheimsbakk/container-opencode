#!/bin/bash
set -e

# Allow upgrade
if [[ "${1,,}" == "upgrade" ]]
then
	UPGRADE=true
else
	UPGRADE=false
fi

# Install skeleton
rsync -ur /etc/skel/ /home/opencode/

# Install NVM
if [[ ! -d "$NVM_DIR" ]]
then
	mkdir -p "$NVM_DIR"
	curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | PROFILE=$HOME/.profile bash
fi

# Source NVM
source "$NVM_DIR/nvm.sh"

# Install Node
which node &> /dev/null || nvm install --lts

# Minimum age set to one week
npm config set min-release-age 7 --location=user

# Install node packages
( ! $UPGRADE && npm list -g opencode-ai )    &> /dev/null || npm i -g "opencode-ai"
( ! $UPGRADE && npm list -g @biomejs/biome ) &> /dev/null || npm i -g "@biomejs/biome"

# Install PIP packages
PATH=$PATH:$HOME/.local/bin

( ! $UPGRADE && which uv )         &> /dev/null || pipx install -qq uv~=$UV_VERSION
( ! $UPGRADE && which pipenv )     &> /dev/null || uv tool install --exclude-newer "1 week" pipenv
( ! $UPGRADE && which ruff )       &> /dev/null || uv tool install --exclude-newer "1 week" ruff
( ! $UPGRADE && which ralph-loop )     &> /dev/null || uv tool install --exclude-newer "1 week" git+https://github.com/aheimsbakk/ralph-loop
( ! $UPGRADE && which gitsem ) &> /dev/null || uv tool install --exclude-newer "1 week" git+https://github.com/aheimsbakk/gitsem

if [[ "${1,,}" == "upgrade" ]]
then
	exit 1
fi

# Start
if [ $# -eq 0 ]; then
	exec bash -l
else
	exec bash -l -c "$*"
fi
