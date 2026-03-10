---
when: 2026-03-10T14:38:30Z
why: GitHub API rate limiting blocked automated builds when downloading the opencode release.
what: Add INSTALL_SOURCE=local build-arg to Containerfile to install from a local .deb instead of downloading
model: github-copilot/claude-sonnet-4.6
tags: [containerfile, build-arg, podman, docs]
---

Added `ARG INSTALL_SOURCE` to the downloader stage in `Containerfile`: when set to `local`, the build copies `opencode-desktop-linux-amd64.deb` from the build context instead of fetching it from the GitHub API, avoiding rate limiting. Default behaviour (download from GitHub) is unchanged. `README.md` updated with a dedicated Build section documenting both modes and the full build-arg reference. Bumped to v0.1.6.
