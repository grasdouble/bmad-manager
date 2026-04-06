#!/usr/bin/env bash

# BMAD Configuration Cleanup Script
# Removes BMAD configuration from the current project
# Run this script from the project where BMAD was installed

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# The script is located in scripts/ of the destination project — the root is the parent folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║        BMAD Configuration Cleanup Script              ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠  WARNING: This script will DELETE BMAD configuration!${NC}"
echo -e "${YELLOW}   Target: $TARGET_DIR${NC}"
echo ""

# ── Scan ─────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}Scanning for BMAD configuration...${NC}"

ITEMS_TO_DELETE=()

# Entire owned directories
for dir in "_bmad" "_bmad-shared" "_bmad-custom" "_bmad-output"; do
    if [ -d "$TARGET_DIR/$dir" ]; then
        echo -e "  ${RED}•${NC} $dir/"
        ITEMS_TO_DELETE+=("dir:$dir")
    fi
done

# bmad-* subdirectories in shared folders
for shared in ".opencode/skills" ".github/skills"; do
    if [ -d "$TARGET_DIR/$shared" ]; then
        for subdir in "$TARGET_DIR/$shared"/bmad-*/; do
            [ -d "$subdir" ] || continue
            rel="$shared/$(basename "$subdir")"
            echo -e "  ${RED}•${NC} $rel/"
            ITEMS_TO_DELETE+=("dir:$rel")
        done
    fi
done

# The cleanup script itself
echo -e "  ${RED}•${NC} scripts/clean-bmad-config.sh"
ITEMS_TO_DELETE+=("file:scripts/clean-bmad-config.sh")

echo ""

if [ ${#ITEMS_TO_DELETE[@]} -eq 1 ]; then
    # Only the script itself — nothing else to clean
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
for item in "${ITEMS_TO_DELETE[@]}"; do
    type="${item%%:*}"
    path="${item#*:}"

    echo -e "${YELLOW}Deleting: $path${NC}"
    if [ "$type" = "dir" ]; then
        rm -rf "$TARGET_DIR/$path"
    else
        rm -f "$TARGET_DIR/$path"
    fi
    echo -e "  ${GREEN}✓${NC} Deleted"
    echo ""
done

# Remove scripts/ if empty after deleting the cleanup script
if [ -d "$TARGET_DIR/scripts" ] && [ -z "$(ls -A "$TARGET_DIR/scripts")" ]; then
    rmdir "$TARGET_DIR/scripts"
fi

# ── Git : exclude ────────────────────────────────────────────────────────────
echo -e "${YELLOW}Cleaning git configuration...${NC}"

# Remove BMAD entries from .git/info/exclude
GIT_DIR=$(git -C "$TARGET_DIR" rev-parse --git-common-dir 2>/dev/null)
if [ -n "$GIT_DIR" ]; then
    case "$GIT_DIR" in
        /*) : ;;
        *)  GIT_DIR="$TARGET_DIR/$GIT_DIR" ;;
    esac
    EXCLUDE_FILE="$GIT_DIR/info/exclude"
    if [ -f "$EXCLUDE_FILE" ]; then
        # Remove lines matching BMAD patterns
        # Use | as delimiter to avoid conflicts with / in paths (BSD sed macOS compatible)
        BEFORE=$(wc -l < "$EXCLUDE_FILE")
        for pattern in "_bmad/" "_bmad-shared/" "_bmad-custom/" "_bmad-output/" "scripts/clean-bmad-config.sh" ".opencode/skills/bmad-*" ".github/skills/bmad-*"; do
            escaped=$(printf '%s\n' "$pattern" | sed 's/[.[\*^$|]/\\&/g')
            sed -i.bak "\\|^${escaped}$|d" "$EXCLUDE_FILE" && rm -f "$EXCLUDE_FILE.bak"
        done
        AFTER=$(wc -l < "$EXCLUDE_FILE")
        REMOVED=$((BEFORE - AFTER))
        if [ "$REMOVED" -gt 0 ]; then
            echo -e "  ${GREEN}✓${NC} Removed $REMOVED entr$([ "$REMOVED" -eq 1 ] && echo "y" || echo "ies") from .git/info/exclude"
        else
            echo -e "  ${YELLOW}⊘${NC} No BMAD entries found in .git/info/exclude"
        fi
    else
        echo -e "  ${YELLOW}⊘${NC} .git/info/exclude not found, skipping"
    fi
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Cleanup Completed Successfully!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Summary:${NC}"
echo -e "  ${BLUE}•${NC} Target:        $TARGET_DIR"
echo -e "  ${BLUE}•${NC} Items deleted: $((${#ITEMS_TO_DELETE[@]}))"
echo ""
echo -e "${BLUE}The project is now clean of BMAD configuration.${NC}"
echo ""
