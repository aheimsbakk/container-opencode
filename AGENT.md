# AGENT.md

Purpose
This file defines repository conventions for agent-originated worklogs and the required workflow agents must follow when making changes. Worklogs are the canonical history that explain when, who, why, what, and which model produced the change.

Location & filename pattern
- Store worklogs under: `agent/worklogs/`
- File name pattern: `agent/worklogs/YYYY-MM-DD-very-short-description.md`
  - Example: `agent/worklogs/2026-02-13-fix-readme-typos.md`
  - If multiple logs on the same day, append `-01`, `-02`, etc.

Worklog structure
- Each worklog MUST start with a YAML front matter block containing at minimum the keys below.
- Required front matter keys:
  - `date`: ISO 8601 timestamp (UTC, include `Z`).
  - `author`: agent id or human name (e.g., `opencode-agent`).
  - `who`: the actor who executed the change (agent id or human email/name).
  - `why`: one-sentence reason for the change.
  - `what`: one-line summary of what was done.
  - `status`: one of `planned`, `in-progress`, `completed`.
  - `model`: model identifier used to produce/assist the change (e.g., `github-copilot/gpt-5-mini`).
  - `model_version`: model version, tag, or date (e.g., `2026-02-13` or `v1.2.0`).
- Optional front matter keys: `model_provider`, `commit` (git SHA), `related` (issue/PR), `tags`, `sensitivity`, `model_config`.

Body
- The body (below the YAML) should be a short human-readable summary (2–6 lines) describing the change, key files touched, and any follow-ups.

Template example
```yaml
---
date: 2026-02-13T16:27:00Z
author: opencode-agent
who: alice@example.com
why: improve onboarding for non-technical users
what: rewrite README intro and add security notes
status: completed
model: github-copilot/gpt-5-mini
model_version: 2026-02-13
model_provider: internal
commit: <git-sha-here>
tags: [docs,security]
---

Short summary: Updated README to explain the container purpose in plain language, corrected typos, and added build/run instructions. Files changed: README.md. Follow-up: add CI check to enforce worklogs for agent-created commits.
```

Agent workflow (required)
1. Read worklogs in `agent/worklogs/` (newest → oldest) and produce a compact context summary focused on the planned task.
2. Create a new worklog file `agent/worklogs/YYYY-MM-DD-short.md` with `status: planned` and fill required metadata (including `model` + `model_version`) before making changes.
3. Perform changes locally or inside the container.
4. Commit changes. If automated, include human review where policy requires it.
5. Update the worklog `status` to `completed`, add the `commit` SHA, and write a 2–6 line summary in the body.
6. Include the compact context summary in the PR description and commit message where applicable.

Compact context guidance
- Produce a short narrative (5–8 sentences; ~100–200 words) summarizing recent relevant worklogs: purpose, major changes, outstanding items.
- Only include entries relevant to the current task (configurable N, default 10 most recent).
- Mention any `status` not equal to `completed` explicitly.

Safety & best practices
- Never include secrets, API keys, or full prompt texts in worklogs.
- If a change touches sensitive areas, set `sensitivity: high` in the header and notify a human reviewer.
- Keep `why` and `what` concise — they enable reliable automated compaction.

Automation suggestions (recommended)
- CI check: require a matching worklog for agent-created commits that modify code; validate required front matter keys.
- Pre-commit hook: prompt creation of a worklog when touching critical directories.
- Script: `scripts/compact-worklogs.sh` to generate compact context automatically from recent worklogs.

Enforcement & troubleshooting
- Missing required fields: abort and ask a human to provide them.
- Duplicate filenames: append numeric suffixes `-01`, `-02`, etc.
- Use UTC timestamps to avoid timezone confusion.

FAQ
- Q: Must the `model` fields be present for all agent changes?
  - A: Yes — at minimum `model` and `model_version` must be present to record provenance.

Where to add this file
- Save this file as `AGENT.md` at the repository root.

If you want, I will create this file and add a sample worklog next.
