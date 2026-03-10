# CONTEXT

This repository provides a Podman/Docker build and runtime environment for the OpenCode agent.
It is intended for local development and testing inside a containerized, isolated environment.

Key points:
- Image tag default: opencode:latest
- The README documents recommended podman run flags and aliases
- `tini` is baked into the image as PID 1 (`ENTRYPOINT ["/usr/bin/tini", "--", ...]`)
  so CTRL+C (SIGINT/SIGTERM) works in both TUI and web-server modes without a trap/wait loop

Created: 2026-02-27
