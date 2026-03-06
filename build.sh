#!/bin/bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINERFILE=""

FORCE=false
NO_CACHE=false
FORCE_DOCKER=false
NAME_OVERRIDE=""
PODMAN_OPTS=()
CMD_OPTS=()

# Determine container runtime: prefer podman, fall back to docker
resolve_runtime() {
    if ${FORCE_DOCKER}; then
        if ! command -v docker &>/dev/null; then
            echo "Error: --docker requested but docker is not installed" >&2
            exit 1
        fi
        echo "docker"
    elif command -v podman &>/dev/null; then
        echo "podman"
    elif command -v docker &>/dev/null; then
        echo "docker"
    else
        echo "Error: neither podman nor docker is installed" >&2
        exit 1
    fi
}

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [PODMAN_RUN_OPTIONS] [-- COMMAND_OPTIONS]

Builds a container image from Containerfile (or Dockerfile as fallback) using
podman (or docker as fallback). If the image already exists, runs the container
instead. Use -f/--force to rebuild an existing image.

Script Options:
  -f, --force       Force rebuild of the container image even if it exists
      --no-cache    Build without using cache (implies --force)
      --docker      Force use of docker even if podman is available
  -n, --name NAME   Override the container image name (default: directory name)
  -h, --help        Show this help message and exit
  -V, --version     Show version information and exit

Argument Separation:
  PODMAN_RUN_OPTIONS   Any options before '--' are passed to the container runtime
  COMMAND_OPTIONS      Any options after '--' are passed to the container command

  Example:
    ${SCRIPT_NAME} -n sphinx --rm -ti -v ./:/mnt -- sphinx-build -b html source public

Container name is derived from the directory containing the build file.

Version: ${VERSION}
EOF
}

# Parse script options; unknown args are collected as podman run options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            FORCE=true   # no-cache only makes sense when building
            shift
            ;;
        --docker)
            FORCE_DOCKER=true
            shift
            ;;
        -n|--name)
            NAME_OVERRIDE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -V|--version)
            echo "${SCRIPT_NAME} ${VERSION}"
            exit 0
            ;;
        --)
            shift
            CMD_OPTS=("$@")
            break
            ;;
        *)
            PODMAN_OPTS+=("$1")
            shift
            ;;
    esac
done

# Resolve container runtime (after argument parsing so --docker is known)
RUNTIME="$(resolve_runtime)"

# Locate Containerfile, fall back to Dockerfile
if [[ -f "${SCRIPT_DIR}/Containerfile" ]]; then
    CONTAINERFILE="${SCRIPT_DIR}/Containerfile"
elif [[ -f "${SCRIPT_DIR}/Dockerfile" ]]; then
    CONTAINERFILE="${SCRIPT_DIR}/Dockerfile"
else
    echo "Error: no Containerfile or Dockerfile found in ${SCRIPT_DIR}" >&2
    exit 1
fi

# Container name = override if given, else name of directory containing the build file
CONTAINER_NAME="${NAME_OVERRIDE:-$(basename "${SCRIPT_DIR}")}"

# Check if the image already exists ('image inspect' works with both podman and docker)
IMAGE_EXISTS=false
if ${RUNTIME} image inspect "${CONTAINER_NAME}" &>/dev/null; then
    IMAGE_EXISTS=true
fi

# Build if the image is missing or --force / --no-cache was requested
if ! ${IMAGE_EXISTS} || ${FORCE}; then
    BUILD_ARGS=()
    if ${NO_CACHE}; then
        BUILD_ARGS+=("--no-cache")
    fi

    echo "Building container image '${CONTAINER_NAME}' using ${RUNTIME}..."
    ${RUNTIME} build "${BUILD_ARGS[@]}" \
        -t "${CONTAINER_NAME}" \
        -f "${CONTAINERFILE}" \
        "${SCRIPT_DIR}"
    echo "Build complete."
fi

# Run the container
echo "Running container '${CONTAINER_NAME}' using ${RUNTIME}..."
${RUNTIME} run --rm \
    "${PODMAN_OPTS[@]+"${PODMAN_OPTS[@]}"}" \
    "${CONTAINER_NAME}" \
    "${CMD_OPTS[@]+"${CMD_OPTS[@]}"}"

