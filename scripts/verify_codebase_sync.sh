#!/bin/bash
set -euo pipefail

# Verify that CODEBASE.md matches the repository on disk.
#
# Check 1 (paths): every file path listed in CODEBASE.md tables exists.
# Check 2 (line references): every line-number reference points at a
# range that contains at least one backtick-quoted token from the same
# row. This catches stale line numbers after code edits.
#
# Usage: scripts/verify_codebase_sync.sh
# Returns 0 if all checks pass, 1 otherwise.

ROOT_DIR=$(dirname "$0")/..
CODEBASE="$ROOT_DIR/CODEBASE.md"

if [ ! -f "$CODEBASE" ]; then
	echo "CODEBASE.md missing"
	exit 1
fi

errors=0

# Extract backtick-quoted strings from a line into TOKENS (newline-separated).
extract_tokens() {
	local line="$1" exclude="$2"
	local tokens
	tokens=$(echo "$line" | grep -oP '`[^`]+`' | tr -d '`' || true)
	local out=""
	local t
	while IFS= read -r t; do
		[ -z "$t" ] && continue
		[ "$t" = "$exclude" ] && continue
		# Short tokens produce false matches; skip them.
		[ ${#t} -lt 4 ] && continue
		out="$out$t"$'\n'
	done <<<"$tokens"
	printf '%s' "$out"
}

# Check that at least one token appears in file range [start, end].
# TOKENS holds candidates, one per line. Prints STALE line on failure.
check_range() {
	local file="$1" start="$2" end="$3" label="$4"
	local segment t found
	[ -z "$end" ] && end="$start"
	if [ "$start" -lt 1 ] || [ "$end" -lt "$start" ]; then
		echo "STALE: invalid range in: $label"
		errors=$((errors + 1))
		return
	fi
	segment=$(sed -n "${start},${end}p" "$ROOT_DIR/$file")
	found=0
	while IFS= read -r t; do
		[ -z "$t" ] && continue
		if printf '%s\n' "$segment" | grep -F -q -- "$t"; then
			found=1
			break
		fi
	done <<<"$TOKENS"
	if [ "$found" -eq 0 ]; then
		echo "STALE: no token from row found in $file lines $start-$end"
		echo "       row: $label"
		errors=$((errors + 1))
	fi
}

# --- Check 1: referenced paths exist ---

# Extract backtick-quoted paths from table rows. Skip lines that don't
# contain a path (e.g. section headers, blank lines).
# Also skip paths that are clearly not file paths (URLs, npm packages, etc.)
while IFS= read -r line; do
	# Only process table rows (starting with |)
	case "$line" in
	'| '*)
		# Extract backtick-quoted strings from the row
		paths=$(echo "$line" | grep -oP '`[^`]+`' | tr -d '`' || true)
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

# --- Check 2: line-number references point at matching content ---

# current_file tracks the file under the nearest "### <file> →" heading.
current_file=""
while IFS= read -r line; do
	case "$line" in
	'### '*)
		current_file=""
		cand=$(echo "$line" | grep -oP '`[^`]+`' | tr -d '`' | head -1 || true)
		if [ -n "$cand" ] && [ -f "$ROOT_DIR/$cand" ]; then
			current_file="$cand"
		fi
		continue
		;;
	esac

	# Bullet rows: "- Lines 24–29: `install_npm_package` helper ..."
	case "$line" in
	'- Line'*)
		range=$(echo "$line" | grep -oP '^\s*-\s+Lines? \K[0-9]+(?:\s*[–-]\s*[0-9]+)?(?=:)' || true)
		[ -z "$range" ] && continue
		range=${range//–/-}
		[ -z "$current_file" ] && continue
		TOKENS=$(extract_tokens "$line" "$current_file")
		start=${range%%[–-]*}
		end=${range##*[–-]}
		[ "$start" = "$range" ] && end=""
		check_range "$current_file" "$start" "$end" "$line"
		continue
		;;
	esac

	# Table rows: "| opencode-ai | npm package | `container-init.sh` line 31 |"
	case "$line" in
	'| '*)
		range=$(echo "$line" | grep -oP '\blines? \K[0-9]+(?:\s*[–-]\s*[0-9]+)?' || true)
		[ -z "$range" ] && continue
		range=${range//–/-}
		# Find the referenced file: first backtick token that exists on disk
		target=""
		while IFS= read -r cand; do
			if [ -f "$ROOT_DIR/$cand" ]; then
				target="$cand"
				break
			fi
		done <<<"$(echo "$line" | grep -oP '`[^`]+`' | tr -d '`' || true)"
		[ -z "$target" ] && continue
		TOKENS=$(extract_tokens "$line" "$target")
		# Also allow the first cell (package name) as a token.
		first_cell=$(echo "$line" | sed -E 's/^\|[[:space:]]*([^|]*)[|].*/\1/' | tr -d '`' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
		if [ ${#first_cell} -ge 4 ]; then
			TOKENS="$TOKENS"$'\n'"$first_cell"
		fi
		start=${range%%[–-]*}
		end=${range##*[–-]}
		[ "$start" = "$range" ] && end=""
		check_range "$target" "$start" "$end" "$line"
		;;
	esac
done <"$CODEBASE"

if [ "$errors" -gt 0 ]; then
	echo "FAILED: $errors problem(s) found"
	exit 1
fi

echo "OK: all paths and line references in CODEBASE.md are valid"
