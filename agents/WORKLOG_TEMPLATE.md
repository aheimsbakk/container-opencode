1: Worklog (create BEFORE making edits)

2: Path and filename
3: - Place under: `agents/worklogs/YYYY-MM-DD-HH-mm-{short-desc}.md`

4: Front matter (MUST contain ONLY these keys, in this order):
5: ```yaml
6: ---
7: when: 2026-02-14T12:00:00Z  # ISO 8601 UTC
8: why: one-sentence reason
9: what: one-line summary
10: model: model-id (e.g. github-copilot/gpt-5-mini)
11: tags: [list, of, tags]
12: ---
13: ```

14: Body
15: - 1–3 sentences summarizing the change and files touched. No extra YAML, no secrets, no prompts.

16: Guidance
17: - Create this file before making code edits. Keep it short and factual. This file is the canonical record of intent for the upcoming change and is required by AGENTS.md.

18: Example
19: ```
20: ---
21: when: 2026-02-15T01:23:00Z
22: why: Request transport-mode fields so UI displays correct emojis
23: what: extend estimatedCalls selection to include journeyPattern.line.transportMode
24: model: github-copilot/gpt-5-mini
25: tags: [entur,graphql,ui]
26: ---

27: Add minimal GraphQL selection for `serviceJourney.journeyPattern.line.transportMode` and update parser to set `item.mode`. Files: src/entur.js, src/ui/departure.js, tests/entur.parse.mode.test.mjs
28: ```

(End of file - total 35 lines)
