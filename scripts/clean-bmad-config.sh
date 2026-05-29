#!/usr/bin/env bash
# Usage: bash scripts/clean-bmad-config.sh
#
# BMAD Configuration Cleanup Script
# Removes BMAD configuration from the current project
# Run this script from the project where BMAD was installed

set -e

# The script is located in scripts/ of the destination project — the root is the parent folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/bmad-patterns.sh"
source "$SCRIPT_DIR/lib/delete-items.sh"
source "$SCRIPT_DIR/lib/update-gitexclude.sh"

print_header "BMAD Configuration Cleanup Script   "
echo ""
echo -e "${YELLOW}⚠  WARNING: This script will DELETE BMAD configuration!${NC}"
echo -e "${YELLOW}   Target: $DEST_DIR${NC}"
echo ""

# ── Scan ─────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}Scanning for BMAD configuration...${NC}"

ITEMS_TO_DELETE=()
BMAD_CONTENT_FOUND=false

# Entire owned directories
for dir in "${BMAD_OWNED_DIRS[@]}" "${BMAD_PROMPT_DIRS[@]}"; do
    if [ -d "$DEST_DIR/$dir" ]; then
        echo -e "  ${RED}•${NC} $dir/"
        ITEMS_TO_DELETE+=("$dir")
        BMAD_CONTENT_FOUND=true
    fi
done

# bmad-* entries in shared folders (dirs for .agents/skills etc., files for .github/agents)
for shared in "${BMAD_SHARED_DIRS[@]}" "${BMAD_SKILL_DEST_DIRS[@]}"; do
    if [ -d "$DEST_DIR/$shared" ]; then
        for entry in "$DEST_DIR/$shared"/bmad-*; do
            [ -e "$entry" ] || continue
            rel="$shared/$(basename "$entry")"
            if [ -d "$entry" ]; then
                echo -e "  ${RED}•${NC} $rel/"
            else
                echo -e "  ${RED}•${NC} $rel"
            fi
            ITEMS_TO_DELETE+=("$rel")
            BMAD_CONTENT_FOUND=true
        done
    fi
done

# The cleanup script and its lib files (derived from BMAD_EXCLUDE_PATTERNS)
echo -e "  ${RED}•${NC} scripts/clean-bmad-config.sh"
ITEMS_TO_DELETE+=("scripts/clean-bmad-config.sh")
for pattern in "${BMAD_EXCLUDE_PATTERNS[@]}"; do
    [[ "$pattern" == scripts/lib/* ]] || continue
    if [ -f "$DEST_DIR/$pattern" ]; then
        echo -e "  ${RED}•${NC} $pattern"
        ITEMS_TO_DELETE+=("$pattern")
    fi
done

echo ""

if [ "$BMAD_CONTENT_FOUND" = false ]; then
    # Only the script files themselves — no real BMAD content to clean
    echo -e "${GREEN}✓ No BMAD configuration found. Nothing to clean.${NC}"
    exit 0
fi

# ── Confirmation ─────────────────────────────────────────────────────────────
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}⚠  The items listed above will be PERMANENTLY DELETED.${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -p "Are you ABSOLUTELY SURE? [yes/no]: " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${BLUE}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}Starting deletion...${NC}"
echo ""

# ── Deletion ──────────────────────────────────────────────────────────────────
delete_items "${ITEMS_TO_DELETE[@]}"

# ── Git : exclude ────────────────────────────────────────────────────────────
echo -e "${YELLOW}Cleaning git configuration...${NC}"
echo -e "${YELLOW}⚠  If BMAD is installed on other worktrees of this repo,${NC}"
echo -e "${YELLOW}   removing .git/info/exclude entries will break them.${NC}"
echo ""
read -p "Remove BMAD entries from .git/info/exclude? [yes/no]: " clean_exclude

if [ "$clean_exclude" = "yes" ]; then
    remove_git_exclude "$DEST_DIR"
else
    echo -e "  ${BLUE}⊘${NC} Skipped (git exclude entries preserved)"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
print_success_header "Cleanup Completed Successfully!     "
echo ""
echo -e "${GREEN}Summary:${NC}"
echo -e "  ${BLUE}•${NC} Target:        $DEST_DIR"
echo -e "  ${BLUE}•${NC} Items deleted: ${#ITEMS_TO_DELETE[@]}"
echo ""
echo -e "${BLUE}The project is now clean of BMAD configuration.${NC}"
echo ""
