# BLUEPRINT

Minimal blueprint created by Vibe Agent to record that this repository is a containerized environment
for running the OpenCode agent. Contains only baseline metadata for agent workflows.

Created: 2026-02-27

## Signal Handling (2026-03-10)
`tini` is installed in the image (`apt-get install tini`) and wired as PID 1 via:
```
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/container-init.sh"]
```
This ensures `SIGINT`/`SIGTERM` (CTRL+C) are forwarded to child processes in both
interactive TUI mode and headless web-server mode. No `trap`/`wait` loop is needed
in `container-init.sh`.
