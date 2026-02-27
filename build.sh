#!/usr/bin/env bash
set -euo pipefail

# build.sh - build the container image for this repository
# Usage: ./build.sh [--tool podman|docker] [--no-cache|--cache] [--tag NAME:TAG]

TOOL=podman
TAG=opencode:latest
NOCACHE=--no-cache

usage() {
  cat <<EOF
Usage: $0 [--tool podman|docker] [--no-cache|--cache] [--tag NAME:TAG]

Defaults:
  --tool podman       # preferred (see README)
  --no-cache          # pass --no-cache to builder by default
  --tag opencode:latest
EOF
  exit 1
}

if [ "$#" -gt 0 ]; then
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --tool)
        TOOL="$2"; shift 2;;
      --tag)
        TAG="$2"; shift 2;;
      --no-cache)
        NOCACHE=--no-cache; shift;;
      --cache)
        NOCACHE=; shift;;
      -h|--help)
        usage;;
      *)
        echo "Unknown argument: $1" >&2; usage;;
    esac
  done
fi

if ! command -v "$TOOL" >/dev/null 2>&1; then
  echo "Error: build tool '$TOOL' not found in PATH." >&2
  exit 2
fi

echo "Building image with $TOOL"
echo "Tag: $TAG"
[ -n "$NOCACHE" ] && echo "No cache: enabled"

set -x
"$TOOL" build ${NOCACHE} -t "$TAG" .
set +x

echo "Build complete: $TAG"
