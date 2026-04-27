---
name: gd-shared-update-docs-project-standard
description: Maintains up-to-date documentation for a standard (non-monorepo) project. Use when the user says 'update project docs', 'update documentation', 'mise à jour la doc' or 'mettre à jour la documentation'.
---

# gd-shared-update-docs-project-standard

## Overview

This skill maintains up-to-date documentation in `{docs_output_path}/` for a **standard single-repo project** (not a monorepo). It delegates all analysis and writing to a single subagent that treats the entire repository as one documentation unit — no package splitting, no parallel subagents.

**Why a subagent instead of doing it directly?** A dedicated subagent gets a fresh, isolated context scoped to the documentation task — no cross-contamination with the orchestration conversation, better output quality.

## On Activation

1. **Load config via bmad-init skill** — Use module `bmm`:
   ```
   Use bmad-init skill:
   - module: bmm
   ```
    Store all returned vars for use throughout the skill:
     - `{user_name}` — for greeting
     - `{communication_language}` — for all communications
     - `{document_output_language}` — for generated docs
     - `{project_name}` — project identifier
     - `{project_knowledge}` → alias as `{docs_output_path}` — docs output folder (e.g. `_bmad-docs`)
2. **Greet** `{user_name}` in `{communication_language}`, briefly explain the workflow.

3. **Route to stage** `00-init.md` to begin — load and execute it.

   If config is missing or incomplete, infer values from the project at runtime (read root `package.json` or other manifest). Only ask the user if inference is impossible.

## Stages

| # | Stage | Purpose | Prompt |
|---|-------|---------|--------|
| 0 | init | Run scan, display result, capture user decision (Update / Skip) | `00-init.md` |
| 1 | update-doc | Generate or update the single project documentation file | `01-update-doc.md` |

## Reference

- `references/universal-rules.md` — Rules that apply to every step

## Assets

- `assets/subagent-doc.prompt.md` — Subagent prompt template: project documentation (with `{{variable}}` substitution)
- `assets/project-doc.template.md` — Output template for the project documentation file

## Scripts

- `scripts/scan-project.py` — Deterministic project scanner. Detects if any source files have changed since the last `generatedAtCommit` stored in `{docs_output_path}/project.md`. Run from project root via `python3 scripts/scan-project.py [--root /path/to/repo]`. Base branch auto-detected; override with `--base-branch` if needed. Outputs JSON to stdout.

## Constraints

- **Single-session only:** All workflow state is held in the LLM's context memory. There is no persistence between sessions. If the conversation resets, the skill must be restarted from `00-init.md`.
- **No partial resume:** Interrupted runs cannot be continued in a new session.

## Advanced Usage

### Headless Mode (CI/CD)

Set `{headless}` = true in the skill config vars to skip the HITL confirmation:

```
Use bmad-init skill:
- module: bmm
- vars: ...,headless:true
```

Headless auto-decision: `00-init.md` — if scan detects changes, auto-proceeds to `01-update-doc.md`. If up-to-date, workflow ends.
