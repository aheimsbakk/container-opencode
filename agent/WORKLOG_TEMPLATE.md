Worklog (create BEFORE making edits)

Path and filename
- Place under: `agent/worklogs/YYYY-MM-DD-HH-mm-{short-desc}.md`

Front matter (MUST contain ONLY these keys, in this order):
```yaml
---
when: 2026-02-14T12:00:00Z  # ISO 8601 UTC
why: one-sentence reason
what: one-line summary
model: model-id (e.g. github-copilot/gpt-5-mini)
tags: [list, of, tags]
---
```

Body
- 1–3 sentences summarizing the change and files touched. No extra YAML, no secrets, no prompts.

Guidance
- Create this file before making code edits. Keep it short and factual. This file is the canonical record of intent for the upcoming change and is required by AGENT.md.

Example
```
---
when: 2026-02-15T01:23:00Z
why: Request transport-mode fields so UI displays correct emojis
what: extend estimatedCalls selection to include journeyPattern.line.transportMode
model: github-copilot/gpt-5-mini
tags: [entur,graphql,ui]
---

Add minimal GraphQL selection for `serviceJourney.journeyPattern.line.transportMode` and update parser to set `item.mode`. Files: src/entur.js, src/ui/departure.js, tests/entur.parse.mode.test.mjs
```
