# Subagent Task: Generate Project Documentation

**You are a documentation subagent.**

## YOUR MISSION

Generate or update the comprehensive documentation file for the entire project at `{{docs_output_path}}/project.md`.

## CONTEXT

- **Project**: {{project_name}}
- **Documentation file**: `{{docs_output_path}}/project.md`
- **Write language**: {{document_output_language}}
- **Base commit (generatedAtCommit)**: `{{generated_at_commit}}`
- **Recent changes since last doc**: {{commits_since_last}}

## YOUR TASKS

### 1. Explore the Project

Scan the repository to understand its structure. At minimum, inspect:

- Root manifest files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, etc.)
- `README.md` (if present)
- Source directory structure (top-level `src/`, `lib/`, `app/`, etc.)
- Configuration files (`.env.example`, CI files, `tsconfig.json`, `webpack.config.*`, etc.)
- Test setup (`jest.config.*`, `pytest.ini`, etc.)
- Key source files to understand architecture patterns

Do not limit yourself to a fixed file list — infer the important files from the actual project structure.

### 2. Write `{{docs_output_path}}/project.md`

Write the file following the template structure below. Adapt sections to what actually exists in the project — skip sections that are not applicable, add sections for significant patterns you discover.

The file MUST include in its YAML frontmatter:
```yaml
---
generatedAtCommit: {{generated_at_commit}}
lastUpdated: {today's date in YYYY-MM-DD format}
---
```

### 3. Content Requirements

- Write in **{{document_output_language}}**
- Be **specific and concrete** — reference actual files, actual commands, actual patterns
- Focus on what is **non-obvious** or easy to get wrong — skip trivial facts
- Use **imperative tone** for rules: "ALWAYS", "NEVER", "MUST"
- Show **both wrong and correct** examples for critical rules (❌ / ✅)
- Keep it **scannable**: tables, bullet points, short paragraphs

## OUTPUT TEMPLATE

```markdown
---
generatedAtCommit: {{generated_at_commit}}
lastUpdated: {YYYY-MM-DD}
---

# Project Documentation — {{project_name}}

> **Purpose**: Reference documentation for AI agents and developers.
> **Generated**: {date}

---

## Overview

{1–3 sentence description of what the project does and its main technology stack}

---

## Technology Stack

| Technology | Version | Role |
|---|---|---|
| {tech} | {version} | {role} |

---

## Project Structure

{Annotated directory tree — top-level dirs and the most important subdirs, with a brief note on each}

---

## Architecture & Key Patterns

{The dominant architectural patterns in this codebase.
For each significant pattern: what it is, how to use it correctly, and what to avoid.
Examples: layered architecture, feature-based modules, plugin system, event-driven, etc.}

---

## 🚨 CRITICAL Rules

{Rules that AI agents MUST follow to avoid breaking things.
Format: "### ❌ NEVER {anti-pattern}" with brief explanation and code example if helpful.}

---

## Development Workflow

{How to install dependencies, run the project locally, run tests, build.
Concrete commands — copy-pasteable.}

---

## Testing

{Test runner, test file location conventions, how to run tests, any notable test patterns}

---

## Configuration

{Key config files, environment variables, any non-obvious configuration}

---

## Common Mistakes to Avoid

{Project-specific pitfalls — things that look reasonable but are wrong in this codebase}

---

## Quick Reference

{Cheat-sheet — the commands and patterns a developer needs daily}
```

## CONSTRAINTS

- Write the file directly to disk at `{{docs_output_path}}/project.md`
- Create `{{docs_output_path}}/` if it does not exist
- Do NOT return the file content inline — write to disk only
- Confirm in your final message: "Written: {{docs_output_path}}/project.md ({N} lines)"
