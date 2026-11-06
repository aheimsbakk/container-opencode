---
topic: "OpenCode npm package switched to @opencode/cli"
importance: high
category: decision
tags: [opencode, npm, container-init, dependencies]
created: 2026-11-06T23:14:59Z
model: kompis/qwen3.8-flash-next-iq3_s
---

The managed npm package in `container-init.sh` changed from `opencode-ai` to
`@opencode/cli@latest` (user request; matches the existing
`@playwright/cli@latest` precedent despite RULES.md rule 23). Both packages
ship an `opencode` bin, so the image `CMD ["opencode"]` contract is unchanged.
Old volumes keep a stale `opencode-ai` install; remove with
`npm rm opencode-ai` in `/home/opencode` or recreate the volume.
