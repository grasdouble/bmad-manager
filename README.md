```
  ██████╗ ███╗   ███╗ █████╗ ██████╗
  ██╔══██╗████╗ ████║██╔══██╗██╔══██╗
  ██████╔╝██╔████╔██║███████║██║  ██║
  ██╔══██╗██║╚██╔╝██║██╔══██║██║  ██║
  ██████╔╝██║ ╚═╝ ██║██║  ██║██████╔╝
  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝

  ────────────────────────────────────────────────────────────
  ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
  ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
  ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
  ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
  ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
```

Central hub for BMAD configuration. Manage it once here, deploy it to any repo or worktree with a single command.

> **Disclaimer:** This is an independent personal project and is not affiliated with, endorsed by, or maintained by the [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) team.

---

## What is this?

`bmad-manager` is the single source of truth for your BMAD setup. Instead of maintaining configuration separately in each project, you keep everything here and push it out via a copy script.

---

## Quick start

```bash
pnpm bmad:copy
```

That's it. The script will guide you through the rest.

---

## How it works

The copy script runs four steps:

```
1. Enter the path to the target repo
       ↓
2. Select the destination worktree
       ↓
3. Copy BMAD directories
       ↓
4. Configure placeholders  →  update .git/info/exclude
```

### What gets copied

| Directory | Strategy |
|---|---|
| `_bmad/` | **Full replacement** — always overwritten, no prompt |
| `_bmad-custom/` | **Prompt** — asks before overwriting if it already exists |
| `_bmad-output/` | **Prompt** — asks before overwriting if it already exists |
| `.opencode/skills/bmad-*` | **Selective** — only `bmad-*` subdirs are replaced |
| `.github/skills/bmad-*` | **Selective** — only `bmad-*` subdirs are replaced |
| `scripts/clean-bmad-config.sh` | Copied and made executable |

### Placeholders replaced

After copying, the script scans all copied files and replaces these tokens:

| Placeholder | Default value |
|---|---|
| `BMAD_MANAGER_USERNAME` | `git config user.name` of the target repo |
| `BMAD_MANAGER_PROJECT_NAME` | Remote origin repo name (fallback: folder name) |
| `BMAD_MANAGER_COMMUNICATION_LANGUAGE` | Detected from system locale |
| `BMAD_MANAGER_OUTPUT_LANGUAGE` | `English` |

Press `Enter` at any prompt to accept the default.

### Git exclusion

Copied files are automatically added to `.git/info/exclude` of the target repo so they never appear in `git diff` or `git status`. This works correctly with worktrees.

---

## Uninstalling from a project

A cleanup script is deposited in `scripts/clean-bmad-config.sh` of every destination project. Run it from there:

```bash
bash scripts/clean-bmad-config.sh
```

It will:
- Scan and list all BMAD items found
- Ask for confirmation before deleting anything
- Remove all BMAD directories and `bmad-*` skills
- Clean up the `.git/info/exclude` entries
- Delete itself and the `scripts/` folder if empty

---

## Available commands

```bash
pnpm bmad:copy      # Deploy BMAD config to another repo or worktree
pnpm bmad:update    # Update BMAD method (bmad-method install)
pnpm bmad:status    # Show BMAD method status
pnpm bmad:viewer    # Open BMAD viewer
```

---

## Project structure

```
bmad-manager/
├── package.json
├── _bmad/                          # Core BMAD configuration (owned, always replaced)
├── _bmad-custom/                   # Custom BMAD config (user content, prompt on overwrite)
├── _bmad-output/                   # BMAD outputs (user content, prompt on overwrite)
└── scripts/
    ├── copy-bmad-config.sh         # Main copy script (orchestrator)
    ├── clean-bmad-config.sh        # Cleanup script (also deployed to destination)
    └── lib/
        ├── colors.sh               # ANSI colors and display helpers
        ├── select-worktree.sh      # Step 1+2: repo input → worktree selection
        ├── copy-dirs.sh            # Step 3: copy logic (3 strategies)
        ├── configure-placeholders.sh  # Step 4: default detection + sed replacement
        └── update-gitexclude.sh    # Git exclude update (.git/info/exclude)
```

---

## Compatibility

- **Shell**: bash 3.2+ (macOS native, no `declare -A`)
- **Package manager**: pnpm
- **git worktrees**: fully supported — exclude entries are written to the main repo's `.git/info/exclude` via `--git-common-dir`
- **OS**: macOS and Linux
