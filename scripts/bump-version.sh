#!/usr/bin/env bash
# Bump semantic version in VERSION file: patch|minor|major
set -euo pipefail
if [ $# -ne 1 ]; then
  echo "Usage: $0 [patch|minor|major]" >&2
  exit 2
fi
part=$1
file=VERSION
if [ ! -f "$file" ]; then
  echo "0.1.0" > "$file"
fi
old=$(cat "$file")
IFS='.' read -r major minor patch <<< "$old"
case "$part" in
  patch)
    patch=$((patch + 1))
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  *)
    echo "Unknown part: $part" >&2
    exit 2
    ;;
esac
new="$major.$minor.$patch"
echo "$new" > "$file"
chmod +x "$0"
echo "$old -> $new"
