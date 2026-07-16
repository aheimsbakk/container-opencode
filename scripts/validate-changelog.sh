#!/bin/bash
set -euo pipefail

# Validate that VERSION exists and matches the most recent changelog header
ROOT_DIR=$(dirname "$0")/..
VERSION_FILE="$ROOT_DIR/VERSION"
CHANGELOG="$ROOT_DIR/CHANGELOG.md"

if [ ! -f "$VERSION_FILE" ]; then
	echo "VERSION file missing"
	exit 1
fi

if [ ! -f "$CHANGELOG" ]; then
	echo "CHANGELOG.md missing"
	exit 1
fi

VERSION=$(cat "$VERSION_FILE" | tr -d " \n\r")

# Extract first version header like: ## [0.1.3] - YYYY-MM-DD
TOP_VERSION_LINE=$(grep -m1 '^## \[' "$CHANGELOG" || true)
if [ -z "$TOP_VERSION_LINE" ]; then
	echo "No version header found in CHANGELOG.md"
	exit 1
fi

TOP_VERSION=$(echo "$TOP_VERSION_LINE" | sed -E 's/^## \[([^]]+)\].*$/\1/')

if [ "$VERSION" != "$TOP_VERSION" ]; then
	echo "VERSION ($VERSION) does not match top CHANGELOG entry ($TOP_VERSION)"
	exit 2
fi

echo "OK: $VERSION matches CHANGELOG"
