---
when: 2026-04-09T16:51:56Z
why: Reduce image size and layer count by merging two apt layers and adding --no-install-recommends
what: Merge apt-install layers and add --no-install-recommends to Containerfile
model: opencode/glm-5.1
tags: [containerfile, optimization, layer-merge]
---

Merged the two separate `apt-get update/install` layers into a single layer that installs all packages including the opencode `.deb` inline, and added `--no-install-recommends` to both `eatmydata` bootstrap and main package install to reduce image size. Files touched: `Containerfile`. Version bumped to 0.1.7.