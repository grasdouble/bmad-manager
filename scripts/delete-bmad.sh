#!/usr/bin/env bash
# delete-bmad.sh — Removes BMAD from a target project using a config file
# Usage: bash scripts/delete-bmad.sh [path/to/delete-bmad.config]
#
# Reads the config file to determine which folders and files to delete,
# then prompts for a target project directory and performs the deletion.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/delete-bmad.config}"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/select-worktree.sh"
source "$SCRIPT_DIR/lib/bmad-patterns.sh"

# ── Header ────────────────────────────────────────────────────────────────────
echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║             BMAD Deletion Script                      ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠  WARNING: This script will DELETE BMAD from a target project!${NC}"
echo ""

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}Config: $CONFIG_FILE${NC}"
echo ""

# ── Select destination ────────────────────────────────────────────────────────
select_destination  # → DEST_DIR

# ── Parse config and scan ─────────────────────────────────────────────────────
echo -e "${YELLOW}Scanning for BMAD items in: $DEST_DIR${NC}"
echo ""

ITEMS_TO_DELETE=()

_trim() {
    local s="$1"
    s="${s#"${s%%[! $'\t']*}"}"
    s="${s%"${s##*[! $'\t']}"}"
    echo "$s"
}

while IFS= read -r raw_line; do
    line="${raw_line%%#*}"          # strip inline comments
    line="$(_trim "$line")"        # trim whitespace
    [[ -z "$line" ]] && continue

    local_path="${line%/}"          # strip optional trailing slash

    if [[ "$local_path" == *"*"* ]] || [[ "$local_path" == *"?"* ]]; then
        # Glob pattern — expand against the destination directory
        shopt -s nullglob
        for match in "$DEST_DIR"/$local_path; do
            [ -e "$match" ] && ITEMS_TO_DELETE+=("${match#"$DEST_DIR/"}")
        done
        shopt -u nullglob
    else
        [ -e "$DEST_DIR/$local_path" ] && ITEMS_TO_DELETE+=("$local_path")
    fi
done < "$CONFIG_FILE"

if [ ${#ITEMS_TO_DELETE[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No BMAD items found in target. Nothing to delete.${NC}"
    exit 0
fi

echo -e "${YELLOW}The following items will be deleted:${NC}"
for item in "${ITEMS_TO_DELETE[@]}"; do
    echo -e "  ${RED}•${NC} $item"
done
echo ""

# ── Confirmation ──────────────────────────────────────────────────────────────
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
deleted_count=0
for item in "${ITEMS_TO_DELETE[@]}"; do
    full_path="$DEST_DIR/$item"
    echo -e "${YELLOW}Deleting: $item${NC}"
    if [ -d "$full_path" ]; then
        rm -rf "$full_path"
    else
        rm -f "$full_path"
    fi
    echo -e "  ${GREEN}✓${NC} Deleted"
    echo ""
    deleted_count=$((deleted_count + 1))
done

# Remove scripts/lib/ and scripts/ if they are empty after deletion
for dir in "scripts/lib" "scripts"; do
    if [ -d "$DEST_DIR/$dir" ] && [ -z "$(ls -A "$DEST_DIR/$dir")" ]; then
        rmdir "$DEST_DIR/$dir"
        echo -e "${GREEN}✓${NC} Removed empty directory: $dir"
        echo ""
    fi
done

# ── Git exclude cleanup ───────────────────────────────────────────────────────
echo -e "${YELLOW}Cleaning git configuration...${NC}"
echo -e "${YELLOW}⚠  If BMAD is installed on other worktrees of this repo,${NC}"
echo -e "${YELLOW}   removing .git/info/exclude entries will break them.${NC}"
echo ""
read -p "Remove BMAD entries from .git/info/exclude? [yes/no]: " clean_exclude

if [ "$clean_exclude" = "yes" ]; then
    GIT_DIR=$(git -C "$DEST_DIR" rev-parse --git-common-dir 2>/dev/null)
    if [ -n "$GIT_DIR" ]; then
        case "$GIT_DIR" in
            /*) : ;;
            *)  GIT_DIR="$DEST_DIR/$GIT_DIR" ;;
        esac
        EXCLUDE_FILE="$GIT_DIR/info/exclude"
        if [ -f "$EXCLUDE_FILE" ]; then
            BEFORE=$(wc -l < "$EXCLUDE_FILE")
            for pattern in "${BMAD_EXCLUDE_PATTERNS[@]}"; do
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
    else
        echo -e "  ${YELLOW}⊘${NC} Target is not a git repository, skipping"
    fi
else
    echo -e "  ${BLUE}⊘${NC} Skipped (git exclude entries preserved)"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Deletion Completed Successfully!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Summary:${NC}"
echo -e "  ${BLUE}•${NC} Target:        $DEST_DIR"
echo -e "  ${BLUE}•${NC} Items deleted: $deleted_count"
echo ""
echo -e "${BLUE}The project is now clean of BMAD.${NC}"
echo ""
