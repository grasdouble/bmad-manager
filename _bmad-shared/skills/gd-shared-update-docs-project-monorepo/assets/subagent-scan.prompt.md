# Subagent Task: Scan Monorepo For Documentation Updates

**You are a documentation scanner subagent.**

## YOUR MISSION

Scan the monorepo to identify which packages need documentation updates.

## CONTEXT

- **Project**: {{project_name}}
- **Packages Path**: `{{packages_root}}/`
- **Documentation Path**: `{{docs_output_path}}/`
- **Base branch**: {{base_branch}}

## STRUCTURE TO SCAN

Discover the actual package structure by scanning `{{packages_root}}/` recursively. Do not assume a fixed layout — infer categories from the directory hierarchy (typically the first level under `{{packages_root}}/`).

## YOUR TASKS

### 1. Discover All Packages

Scan `{{packages_root}}/` recursively to find all directories containing a `package.json`.

For each package, extract:

- Package name (from `package.json`)
- Package path (relative to project root)
- Category (inferred from path segment after `{{packages_root}}/`)
- Description (from `package.json` if available)
- Main technologies/dependencies

### 2. Check Existing Documentation

For each discovered package, check if documentation exists:

- `{{docs_output_path}}/documentation/{category}/{package-name}.md`
- `{{docs_output_path}}/context/{category}/{package-name}.context.md`

### 3. Identify Updates Needed

For each package, read the `generatedAtCommit` field from the existing documentation frontmatter (if it exists), then detect source changes since that commit using `--first-parent` against `{{base_branch}}`:

```bash
git log {generatedAtCommit}..{{base_branch}} --first-parent --format="%H %s" -- {package_path}/
```

`--first-parent` ensures only commits that landed on the main branch are counted, ignoring feature-branch history. This works correctly for both squash-merge and regular merge workflows.

**Status decision for each package:**

- Doc does NOT exist → `missing`
- `generatedAtCommit` absent from frontmatter → `needs_update` (reason: "no commit reference")
- git log output is EMPTY → `up_to_date`
- git log output is NON-EMPTY → `needs_update` (include commit list)

### 4. Determine current_commit

Run `git rev-parse {{base_branch}}` — this is the value to use as `generatedAtCommit` when writing new docs. Always reference the base branch tip, never the current feature branch HEAD.

## OUTPUT FORMAT

Return a structured JSON report:

```json
{
  "scan_completed": true,
  "project_name": "{{project_name}}",
  "packages_root": "{{packages_root}}",
  "docs_output_path": "{{docs_output_path}}",
  "base_branch": "{{base_branch}}",
  "current_head_commit": "abc1234def5678",
  "total_packages": 12,
  "packages": [
    {
      "name": "@scope/package-name",
      "path": "{packages_root}/category/package-name",
      "category": "category",
      "description": "Package description",
      "has_doc": true,
      "has_context": true,
      "generated_at_commit": "abc123",
      "status": "needs_update",
      "reason": "2 commits since last generation",
      "commits_since_last": [
        "abc1234 fix: something (#12)",
        "def5678 feat: something else (#13)"
      ]
    }
  ],
  "packages_needing_update": ["@scope/package-name"],
  "packages_up_to_date": ["@scope/other-package"],
  "summary": {
    "total": 12,
    "up_to_date": 9,
    "needs_update": 2,
    "missing_docs": 1
  }
}
```

## CONSTRAINTS

- **DO NOT modify any files** — read-only scan
- **DO NOT create documentation** — only identify what needs updating
- Return ONLY the structured JSON report

## BEGIN SCAN

1. Run `git symbolic-ref refs/remotes/origin/HEAD` to confirm base branch (or use `{{base_branch}}` directly)
2. Run `git rev-parse {{base_branch}}` to get `current_head_commit`
3. List `{{packages_root}}/` to discover package categories
4. For each package: read `package.json`, check doc existence in `documentation/` and `context/`, read `generatedAtCommit`, run git log
5. Return the JSON report
