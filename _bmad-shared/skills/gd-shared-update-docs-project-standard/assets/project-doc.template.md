# Project Documentation Template

Template for `{docs_output_path}/project.md`.
Used by `01-update-doc.md` to guide the documentation subagent.

---

## File Structure

```markdown
---
generatedAtCommit: {commit-sha}
lastUpdated: YYYY-MM-DD
---

# Project Documentation — {project_name}

> **Purpose**: Reference documentation for AI agents and developers.
> **Generated**: {date}

---

## Overview

{1–3 sentence description of what the project does and its main technology stack.}

---

## Technology Stack

| Technology | Version | Role |
|---|---|---|
| {tech} | {version} | {role} |

---

## Project Structure

{Annotated directory tree — top-level dirs with brief notes on each.}

---

## Architecture & Key Patterns

{The dominant architectural patterns of the project.
For each significant pattern: what it is, how to use it correctly, and what to avoid.}

---

## 🚨 CRITICAL Rules

{Rules that MUST be followed to avoid breaking things.}

---

## Development Workflow

{Install, run, test, build — concrete commands.}

---

## Testing

{Test runner, conventions, how to run.}

---

## Configuration

{Key config files and environment variables.}

---

## Common Mistakes to Avoid

{Project-specific pitfalls.}

---

## Quick Reference

{Daily cheat sheet.}
```

---

## Required Frontmatter Fields

| Field | Description |
|---|---|
| `generatedAtCommit` | SHA of the base branch tip at generation time — used by `scan-project.py` to detect stale docs |
| `lastUpdated` | ISO date (YYYY-MM-DD) — used for display in scan results |

---

## Priority Sections

These sections MUST always be included:

1. **Overview** — What the project is and does
2. **Technology Stack** — Current versions (from manifest files)
3. **Architecture & Key Patterns** — The dominant patterns (discovered, not assumed)
4. **CRITICAL Rules** — Non-obvious constraints for AI agents
5. **Development Workflow** — How to install, run, and test

Additional sections should be added based on what actually exists in the project.

---

## Writing Style

- **Imperative tone**: "ALWAYS", "NEVER", "MUST"
- **Code examples**: Show both ❌ wrong and ✅ correct for critical rules
- **Concise**: Focus on non-obvious, project-specific information
- **Scannable**: Use tables and bullet points

### Critical Rules Format

````markdown
### ❌ NEVER {anti-pattern}

{Brief explanation why}

```
// ❌ FORBIDDEN
{bad example}

// ✅ CORRECT
{good example}
```
````
