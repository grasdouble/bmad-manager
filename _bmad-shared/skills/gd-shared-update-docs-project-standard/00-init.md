---
name: 00-init
description: Run scan first, display result, then capture user decision (Update / Skip)
scanScript: "scripts/scan-project.py"
nextStepUpdate: "01-update-doc.md"
---

Communicate with user in `{communication_language}`. Write document content in `{document_output_language}`.

# Step 0: Scan & Decision

## MANDATORY EXECUTION RULES (READ FIRST)

### Universal Rules

→ See `references/universal-rules.md` — applies to all steps.

### Step-Specific Rules

- 🎯 Run scan FIRST (deterministic script) before presenting the menu — gives user context on whether docs are current
- 🎯 This step captures the decision — no analysis, no LLM subagents (only the scan script)
- FORBIDDEN to proceed without user selecting a valid option (unless headless)
- Route to the correct step based on user selection

## EXECUTION PROTOCOLS

- Run scan script (always, before presenting the menu)
- Check for headless mode — auto-proceed if active
- Display scan result + decision menu
- Halt and wait for user selection
- Execute routing based on choice

---

## 0. RUN SCAN

Run the scan script before presenting anything to the user (non-blocking — if it fails, continue without scan results):

```bash
python3 {scanScript} --root .
```

If `python3` is not available, try `python {scanScript}`.

If the script succeeds and output is valid JSON:
- Store `scan_pre_run = true` in workflow state
- Store `project_status`, `generated_at_commit`, `commits_since_last`, `current_head_commit`, and `days_since_last` from JSON output
- Continue to section 1

If the script fails or output is not valid JSON:
- Set `scan_pre_run = false`
- Continue to section 1 (the menu will still be shown, but without scan context)

---

## 1. DISPLAY WELCOME + SCAN RESULTS

### 1.1 Welcome Banner

Display:

```
🔄 **Update Project Documentation Workflow**

This workflow uses a single subagent to generate or update the project documentation.

Architecture:
  • Step 0 — Scan project (deterministic script)
  • Step 1 — Project documentation (1 subagent)
```

### 1.2 Scan Results (if available)

If `scan_pre_run = true`, display:

```
📊 **Scan Results**

Project: {project_name}
Documentation file: {docs_output_path}/project.md
Status: {project_status}      ← "up_to_date" | "needs_update" | "missing"

{if project_status == "up_to_date"}
✅ Documentation is current.
   Last generated at commit: {generated_at_commit}
   Days since last update: {days_since_last}

💡 Suggestion: [S] Skip — no changes detected

{else if project_status == "needs_update"}
⚠️  {commits_count} commit(s) since last documentation.
   Last generated at commit: {generated_at_commit}
   Recent changes:
{for each commit in commits_since_last (max 10)}
     • {commit}
{/for}

💡 Suggestion: [U] Update — changes detected since last run

{else if project_status == "missing"}
❌ No documentation found yet.

💡 Suggestion: [U] Update — create initial documentation
{/if}
```

If `scan_pre_run = false`, display:

```
⚠️  Scan could not run automatically. Proceed manually.
```

---

## 2. PRESENT DECISION MENU

### 2.0 HEADLESS MODE CHECK

If `{headless}` = true:
- If `project_status == "up_to_date"`: Display `"🤖 Headless mode: documentation is current. Skipping."` End workflow.
- Otherwise: Set decision = U. Display `"🤖 Headless mode active: auto-proceeding to documentation update."` Load, read completely, and execute `{nextStepUpdate}`. **Skip all remaining sections in this file.**

### 2.1 Display Menu

```
**What would you like to do?**

[U] Update — Generate or update project documentation
[S] Skip   — Exit without changes

Your choice:
```

### 2.2 Menu Handling Logic

- **IF U:** Load, read completely, and execute `{nextStepUpdate}`.
- **IF S:** Display "Skipping. No changes made." End workflow.
- **IF any other input or question:** Answer the user's query, then redisplay this menu.

### 2.3 Execution Rules

- ⏸️ ALWAYS halt and wait for user selection after displaying the menu
- ONLY proceed after a valid option (U/S) is selected
- After answering any query or comment, return to the menu display

---

## Stage Progression

- `{nextStepUpdate}` (`01-update-doc.md`) — when U is selected
- End workflow — when S is selected or headless + up_to_date

---

## 🚨 SYSTEM SUCCESS/FAILURE METRICS

### ✅ SUCCESS

- Scan executed (or gracefully skipped on failure)
- Welcome message + scan result displayed
- Decision menu presented
- Valid user selection captured
- Correct routing executed

### ❌ SYSTEM FAILURE

- Displaying menu before scan runs
- Proceeding without user input
- Routing to wrong step
- Failing to redisplay menu after non-option input

**Master Rule:** This step captures the decision only. No documentation work is done here.
