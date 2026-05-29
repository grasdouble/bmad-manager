#!/usr/bin/env bash
# Shared deletion logic — delete items and cleanup empty script dirs
# Requires: DEST_DIR, RED, GREEN, YELLOW, NC (from colors.sh)
# Compatible with bash 3.2 (macOS default)

# delete_items ITEM [ITEM ...]
#   Deletes each item (relative path) from DEST_DIR.
#   Cleans up scripts/lib and scripts/ if left empty afterward.
delete_items() {
    for item in "$@"; do
        local full_path="$DEST_DIR/$item"
        echo -e "${YELLOW}Deleting: $item${NC}"
        if [ -d "$full_path" ]; then
            rm -rf "$full_path"
        else
            rm -f "$full_path"
        fi
        echo -e "  ${GREEN}✓${NC} Deleted"
        echo ""
    done

    # Remove scripts/lib/ and scripts/ if they are empty after deletion
    for dir in "scripts/lib" "scripts"; do
        if [ -d "$DEST_DIR/$dir" ] && [ -z "$(ls -A "$DEST_DIR/$dir")" ]; then
            rmdir "$DEST_DIR/$dir"
            echo -e "${GREEN}✓${NC} Removed empty directory: $dir"
            echo ""
        fi
    done
}
