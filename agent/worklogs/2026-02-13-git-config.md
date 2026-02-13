---
date: 2026-02-13T18:03:00Z
who: opencode-agent
why: avoid overwriting existing user gitconfig
what: update container-init.sh to conditionally create .gitconfig only if it doesn't exist
model: opencode/big-pickler
tags: [devops,scripts]
---

Updated `container-init.sh` to check if `.gitconfig` already exists before creating it, preventing overwriting of user-defined git configuration.
