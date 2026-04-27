#!/usr/bin/env bash
# Shared BMAD patterns — sourced by update-gitexclude.sh and clean-bmad-config.sh

BMAD_EXCLUDE_PATTERNS=(
    "_bmad/"
    "_bmad-shared/"
    "_bmad-custom/"
    # "_bmad-output/"
    "scripts/clean-bmad-config.sh"
    "scripts/lib/bmad-patterns.sh"
    ".agents/skills/bmad-*"
    ".agents/skills/gd-shared-*"
)
