#!/usr/bin/env bash
# delete-bmad.sh — Removes BMAD from this repo using a config file
# Usage: bash scripts/delete-bmad.sh [path/to/delete-bmad.config]
#
# Reads the config file to determine which folders and files to delete,
# then performs the deletion in the repo root.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/delete-bmad.config}"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/bmad-patterns.sh"
source "$SCRIPT_DIR/lib/delete-items.sh"

# ── Header ────────────────────────────────────────────────────────────────────
print_header "BMAD Deletion Script                "
echo ""
echo -e "${YELLOW}⚠  WARNING: This script will DELETE BMAD from this repo!${NC}"
echo -e "${YELLOW}   Target: $DEST_DIR${NC}"
echo ""

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}Config: $CONFIG_FILE${NC}"
echo ""

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
delete_items "${ITEMS_TO_DELETE[@]}"

# ── Summary ───────────────────────────────────────────────────────────────────
print_success_header "Deletion Completed Successfully!    "
echo ""
echo -e "${GREEN}Summary:${NC}"
echo -e "  ${BLUE}•${NC} Target:        $DEST_DIR"
echo -e "  ${BLUE}•${NC} Items deleted: ${#ITEMS_TO_DELETE[@]}"
echo ""
echo -e "${BLUE}The repo is now clean of BMAD. Ready for a fresh install.${NC}"
echo ""
