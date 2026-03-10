---
when: 2026-03-10T14:21:52Z
why: Improve README alias snippet so it replaces existing aliases instead of only appending, and avoids repeating the command string.
what: Refactor .bashrc alias setup snippet to use variables and sed-based replacement
model: github-copilot/claude-sonnet-4.6
tags: [docs, readme, aliases]
---

Updated the alias setup snippet in `README.md` to define each alias once in a variable (`OC`, `OCW`) and use `sed -i` to replace an existing line or append if absent. Bumped version to 0.1.4.
