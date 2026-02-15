# Agent Protocol

## 1. Worklogs

### 1.1. Granular Worklog (Long-term Memory)
- **Action:** Every change requires a worklog file.
- **Path:** `agent/worklogs/YYYY-MM-DD-HH-mm-{short-desc}.md`
  - **Date and time:** Use `date` command to fetch date and time.
- **Front Matter (Strict):** Must contain ONLY these keys:
  ```yaml
  ---
  when: 2026-02-14T12:00:00Z  # ISO 8601 UTC
  why: one-sentence reason
  what: one-line summary
  model: model-id (e.g. github-copilot/gpt-4)
  tags: [list, of, tags]
  ---
  ```
- **Body:** 1–3 sentences summarizing changes and files touched.
- **Safety:** NO secrets, API keys, or prompt text.
- **Template:** agent/WORKLOG_TEMPLATE.md
- **Validate:** ALWAYS validate the worklog with scripts/validate_worklogs.sh

### 1.2. State Compaction (Short-term Memory)
- **Action:** Immediately after creating a granular log, create or update `agent/CONTEXT.md`.
- **Constraint:** This file MUST stay under 20 lines.
- **Structure:**
    - **Current Goal:** The high-level "vibe" we are chasing right now.
    - **Last 3 Changes:** Bullet points referencing the last 3 worklog filenames.
    - **Next Steps:** The immediate next 2 tactical moves.

### 1.3. Context Hygiene
- **Rule:** If `agent/CONTEXT.md` exceeds 20 lines, the agent must "garbage collect" by moving older tactical notes into a new worklog and resetting the `agent/CONTEXT.md` to the current priority only.
- **Safety:** Never include raw code snippets or secrets in these files; use descriptive summaries only.

## 2. Workflow
1. **Context:** Read recent logs in `agent/worklogs/`.
2. **Create:** Generate the worklog file BEFORE committing.
3. **Commit:** Push changes + worklog.
   - **Commit message:** Conventional commit message format. 
4. **Diary (Optional):** If compressing context, append to `DIARY.md`:
   - Header: `## YYYY-MM-DD HH:mm`
   - Content: Bulleted summary of the session.

## 3. Versioning
- **Rule:** If a file contains `VERSION="x.y.z"`, you MUST update it (SemVer).
  - Patch: Bug fix.
  - Minor: Feature.
  - Major: Breaking change.
- **Action:** Mention the new version in the worklog body.

## 4. Enforcement
- Worklogs must validate against the schema above.
- If `scripts/bump-version.sh` exists, use it. Otherwise, update manually.
- Do not create Github Actions, or any CI/CD under `.github`.
