1: # Agent Protocol

2: 
3: ## 1. Worklogs

4: 
5: ### 1.1. Granular Worklog (Long-term Memory)
6: - **Action:** Every change requires a worklog file.
7: - **Path:** `agents/worklogs/YYYY-MM-DD-HH-mm-{short-desc}.md`
8:   - **Date and time:** Use `date` command to fetch date and time.
9: - **Front Matter (Strict):** Must contain ONLY these keys:
10:   ```yaml
11:   ---
12:   when: 2026-02-14T12:00:00Z  # ISO 8601 UTC
13:   why: one-sentence reason
14:   what: one-line summary
15:   model: model-id (e.g. github-copilot/gpt-4)
16:   tags: [list, of, tags]
17:   ---
18:   ```
19: - **Body:** 1–3 sentences summarizing changes and files touched.
20: - **Safety:** NO secrets, API keys, or prompt text.
21: - **Template:** agents/WORKLOG_TEMPLATE.md
22: - **Validate:** ALWAYS validate the worklog with scripts/validate_worklogs.sh

23: 
24: ### 1.2. State Compaction (Short-term Memory)
25: - **Action:** Immediately after creating a granular log, create or update `agents/CONTEXT.md`.
26: - **Constraint:** This file MUST stay under 20 lines.
27: - **Structure:**
28:     - **Current Goal:** The high-level "vibe" we are chasing right now.
29:     - **Last 3 Changes:** Bullet points referencing the last 3 worklog filenames.
30:     - **Next Steps:** The immediate next 2 tactical moves.

31: 
32: ### 1.3. Context Hygiene
33: - **Rule:** If `agents/CONTEXT.md` exceeds 20 lines, the agent must "garbage collect" by moving older tactical notes into a new worklog and resetting the `agents/CONTEXT.md` to the current priority only.
34: - **Safety:** Never include raw code snippets or secrets in these files; use descriptive summaries only.

35: 
36: ## 2. Workflow
37: 1. **Context:** Read recent logs in `agents/worklogs/`.
38: 2. **Create:** Generate the worklog file BEFORE committing.
39: 3. **Commit:** Push changes + worklog.
40:    - **Commit message:** Conventional commit message format. 
41: 4. **Diary (Optional):** If compressing context, append to `DIARY.md`:
42:    - Header: `## YYYY-MM-DD HH:mm`
43:    - Content: Bulleted summary of the session.

44: ## 3. Versioning
45: - **Rule:** If a file contains `VERSION="x.y.z"`, you MUST update it (SemVer).
46:   - Patch: Bug fix.
47:   - Minor: Feature.
48:   - Major: Breaking change.
49: - **Action:** Mention the new version in the worklog body.

50: ## 4. Enforcement
51: - Worklogs must validate against the schema above.
52: - If `scripts/bump-version.sh` exists, use it. Otherwise, update manually.
53: - Do not create Github Actions, or any CI/CD under `.github`.


(End of file - total 56 lines)
