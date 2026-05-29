#!/usr/bin/env bash
# Shared BMAD configuration — sourced by copy-dirs.sh, update-gitexclude.sh and clean-bmad-config.sh

# Directories exclusively owned by BMAD → full replacement, no prompt
BMAD_OWNED_DIRS=(
    "_bmad"
    ".agents"
    ".claude"
)

# BMAD directories with potential user content → prompt if the directory already exists
BMAD_PROMPT_DIRS=(
    "_bmad-custom"
    "_bmad-output"
)

# Shared directories where only bmad-* entries are managed (source = same dir in source repo)
# Used by clean-bmad-config.sh and as simple shared copy targets
BMAD_SHARED_DIRS=(
    ".github/agents"
)

# Custom skills source → merged into BMAD_SKILL_DEST_DIRS after the owned dir copy
BMAD_SKILLS_CUSTOM_SOURCE="_bmad-shared/skills"
# Destination dirs that receive the custom skills merge
BMAD_SKILL_DEST_DIRS=(
    ".agents/skills"
    ".claude/skills"
)

# Patterns added/removed from .git/info/exclude
BMAD_EXCLUDE_PATTERNS=(
    "_bmad/"
    "_bmad-shared/"
    "_bmad-custom/"
    "_bmad-output/"
    "scripts/clean-bmad-config.sh"
    "scripts/lib/bmad-patterns.sh"
    "scripts/lib/colors.sh"
    ".agents/skills/bmad-*"
    ".claude/skills/bmad-*"
    ".agents/skills/gd-shared-*"
    ".claude/skills/gd-shared-*"
    ".github/agents/bmad-*"
)

