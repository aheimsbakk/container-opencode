#!/bin/bash
set -e

if [ $# -ne 1 ]; then
	echo "Usage: $0 [patch|minor|major]"
	exit 1
fi

VERSION_FILE="VERSION"

if [ ! -f "$VERSION_FILE" ]; then
	echo "0.0.0" >"$VERSION_FILE"
fi

CURRENT=$(cat "$VERSION_FILE")
MAJOR=$(echo "$CURRENT" | cut -d. -f1)
MINOR=$(echo "$CURRENT" | cut -d. -f2)
PATCH=$(echo "$CURRENT" | cut -d. -f3)

case "$1" in
patch) PATCH=$((PATCH + 1)) ;;
minor)
	MINOR=$((MINOR + 1))
	PATCH=0
	;;
major)
	MAJOR=$((MAJOR + 1))
	MINOR=0
	PATCH=0
	;;
*)
	echo "Invalid bump type: $1 (use patch, minor, or major)"
	exit 1
	;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "$NEW_VERSION" >"$VERSION_FILE"
echo "Bumped $CURRENT -> $NEW_VERSION"
