---
when: 2026-03-10T14:25:04Z
why: CTRL+C did not stop the container when running opencode web, requiring a force quit.
what: Add signal trapping to container-init.sh for graceful SIGINT/SIGTERM handling
model: github-copilot/claude-sonnet-4.6
tags: [container, shell, bugfix]
---

Replaced `exec "${@:-/bin/bash}"` in `container-init.sh` with a background-launch pattern that traps `SIGINT`/`SIGTERM` and forwards them to the child process, then waits for it to exit. This allows CTRL+C to gracefully stop the container when running `opencode web`. Bumped version to 0.1.5.
