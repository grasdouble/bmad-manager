---
name: 01-update-doc
description: Generate or update the project documentation file using a dedicated subagent
subagentDocTemplate: "assets/subagent-doc.prompt.md"
---

Communicate with user in `{communication_language}`. Write document content in `{document_output_language}`.

# Step 1: Update Project Documentation (Subagent)

**Objective:** Generate or update `{docs_output_path}/project.md` — a comprehensive documentation of the entire project — using a **single dedicated subagent**.

---

## MANDATORY EXECUTION RULES (READ FIRST)

### Universal Rules

→ See `references/universal-rules.md` — applies to all steps.

### Step-Specific Rules

- 🚫 NEVER document the project yourself — delegate to the subagent
- Launch exactly ONE documentation subagent using `{subagentDocTemplate}`
- The subagent writes the file directly to disk — no content is returned inline
- ⏸️ HALT and wait for user input ONLY on subagent errors

## EXECUTION PROTOCOLS

- Announce the step
- Load and populate the subagent prompt template
- Launch the subagent
- Report result
- End workflow

---

## ⚠️ ORCHESTRATOR ROLE

You are the **ORCHESTRATOR**. You DO NOT write documentation yourself.
You DELEGATE to a subagent.

---

## 1. ANNOUNCE STEP

Display to user:

```
📄 **Step 1/1: Project Documentation Update**

Launching documentation subagent for {project_name}...
```

---

## 2. PREPARE AND LAUNCH SUBAGENT

### 2.1 Load Template

Read the subagent prompt template: `{subagentDocTemplate}`

### 2.2 Substitute Variables

Replace all `{{variable}}` placeholders in the template with actual values:

| Placeholder | Value |
|---|---|
| `{{project_name}}` | `{project_name}` |
| `{{docs_output_path}}` | `{docs_output_path}` |
| `{{document_output_language}}` | `{document_output_language}` |
| `{{generated_at_commit}}` | `{current_head_commit}` (from scan, or run `git rev-parse HEAD` if unavailable) |
| `{{commits_since_last}}` | Formatted list from scan result, or `"(full regeneration)"` if no prior doc |

### 2.3 Launch Subagent

Call `runSubagent` with:
- **description**: `"Document project {project_name}"`
- **prompt**: Populated template content

### 2.4 Wait for Result

The subagent will write `{docs_output_path}/project.md` directly to disk.

---

## 3. PROCESS RESULT

### 3.1 Verify Output

Confirm that `{docs_output_path}/project.md` exists on disk after the subagent completes.

- **If the file exists:** Proceed to section 4.
- **If the file does not exist:** Treat as a subagent error — go to section 3.2.

### 3.2 Handle Subagent Errors

> **Headless bypass:** If `{headless}` = true, auto-select **[R]** (Retry once) then **[A]** (Abort) on second failure.

```
❌ Documentation subagent failed or did not produce the expected file.

{error_description}

Options:
[R] Retry  — Relaunch the subagent with the same prompt
[A] Abort  — Stop the workflow without changes

Your choice:
```

- **IF R:** Re-invoke subagent with same parameters. On second failure, show error again with only **[A]**.
- **IF A:** Display "Workflow aborted. No changes made." End workflow.
- **IF any other input:** Answer the user's query, then redisplay this menu.

---

## 4. REPORT AND COMPLETE

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 **Documentation Update Complete**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Project documentation updated.

📁 File: {docs_output_path}/project.md
```

End workflow.

---

## 🚨 SYSTEM SUCCESS/FAILURE METRICS

### ✅ SUCCESS

- Documentation subagent launched with correct prompt
- `{docs_output_path}/project.md` created or updated on disk
- Completion summary displayed

### ❌ SYSTEM FAILURE

- Writing documentation content directly (not via subagent)
- Reporting success before verifying file existence
- Proceeding without user input on error
