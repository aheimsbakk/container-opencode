#!/bin/bash
set -euo pipefail

# Verify that every file path listed in CODEBASE.md exists on disk.
# Scans CODEBASE.md for file references (lines starting with `| ` containing
# backtick-delimited paths) and checks each exists.
#
# Usage: scripts/verify_codebase_sync.sh
# Returns 0 if all paths exist, 1 otherwise.

ROOT_DIR=$(dirname "$0")/..
CODEBASE="$ROOT_DIR/CODEBASE.md"

if [ ! -f "$CODEBASE" ]; then
	echo "CODEBASE.md missing"
	exit 1
fi

errors=0

# Extract backtick-quoted paths from table rows. Skip lines that don't
# contain a path (e.g. section headers, blank lines).
# Also skip paths that are clearly not file paths (URLs, npm packages, etc.)
while IFS= read -r line; do
	# Only process table rows (starting with |)
	case "$line" in
	'| '*)
		# Extract backtick-quoted strings from the row
		paths=$(echo "$line" | grep -oP '`\K[^`]+(?=`)' || true)
		for p in $paths; do
			# Skip non-file paths
			case "$p" in
			http://* | https://* | git+* | npm | latest | node:26 | Docker\ Hub | opencode-ai | *@* | *.bin | */*.bin | Debian* | PYPI*) continue ;;
			esac
			# Skip paths that are clearly package names or non-file references
			case "$p" in
			*/*.sh | */*.md | */*.json | Containerfile | VERSION | scripts/*)
				full_path="$ROOT_DIR/$p"
				if [ ! -e "$full_path" ]; then
					echo "MISSING: $p (from line: $line)"
					errors=$((errors + 1))
				fi
				;;
			esac
		done
		;;
	esac
done <"$CODEBASE"

if [ "$errors" -gt 0 ]; then
	echo "FAILED: $errors path(s) missing"
	exit 1
fi

echo "OK: all paths in CODEBASE.md exist on disk"
