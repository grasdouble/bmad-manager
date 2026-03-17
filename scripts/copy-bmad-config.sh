#!/usr/bin/env bash

# BMAD Configuration Copy Script
# Copies BMAD configuration from this repo (bmad-manager) to any worktree or external repo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load modules
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/select-worktree.sh"
source "$SCRIPT_DIR/lib/copy-dirs.sh"
source "$SCRIPT_DIR/lib/configure-placeholders.sh"
source "$SCRIPT_DIR/lib/update-gitexclude.sh"

# ── Header ───────────────────────────────────────────────────────────────────
print_header "BMAD Configuration Copy Script      "
echo -e "${GREEN}Source (bmad-manager):${NC} $SOURCE_DIR"
echo ""

# ── Steps ────────────────────────────────────────────────────────────────────
select_destination    # → DEST_DIR

copy_dirs             # → DIRS_TO_COPY

print_header "Configure BMAD settings             "
echo ""
configure_placeholders

print_header "Updating git exclude                 "
echo ""
update_git_exclude

# ── Final summary ────────────────────────────────────────────────────────────
print_success_header "Copy Operation Successful!          "
echo ""
echo -e "${GREEN}Summary:${NC}"
echo -e "  ${BLUE}•${NC} Source:      $SOURCE_DIR"
echo -e "  ${BLUE}•${NC} Destination: $DEST_DIR"
echo -e "  ${BLUE}•${NC} Directories copied: ${#DIRS_TO_COPY[@]}"
for dir in "${DIRS_TO_COPY[@]}"; do
    echo -e "    ${GREEN}✓${NC} $dir"
done

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Navigate to the destination: ${YELLOW}cd $DEST_DIR${NC}"
echo -e "  2. Verify the configuration in ${YELLOW}_bmad/core/config.yaml${NC}"
echo ""
