#!/usr/bin/env bash
# Shared BMAD configuration — sourced by copy-dirs.sh, update-gitexclude.sh and clean-bmad-config.sh

# Directories exclusively owned by BMAD → full replacement, no prompt
BMAD_OWNED_DIRS=(
    "_bmad"
    "_bmad-shared"
)

# BMAD directories with potential user content → prompt if the directory already exists
BMAD_PROMPT_DIRS=(
    "_bmad-custom"
    "_bmad-output"
)

# Shared directories → only "bmad-*" subdirectories are managed
BMAD_SHARED_DIRS=(
    ".agents/skills"
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
    ".agents/skills/gd-shared-*"
)

