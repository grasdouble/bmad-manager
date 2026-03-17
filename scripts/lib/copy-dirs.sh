#!/usr/bin/env bash
# Copy BMAD directories to the destination
# Requires: SOURCE_DIR, DEST_DIR, RED, GREEN, YELLOW, BLUE, NC (depuis colors.sh)
# Expose: DIRS_TO_COPY

# Directories exclusively owned by BMAD → full replacement, no prompt
BMAD_OWNED_DIRS=(
    "_bmad"
)

# BMAD directories with potential user content → prompt if the directory already exists
BMAD_PROMPT_DIRS=(
    "_bmad-custom"
    "_bmad-output"
)

# Shared directories → only "bmad-*" subdirectories are removed before copying
BMAD_SHARED_DIRS=(
    ".opencode/skills"
    ".github/skills"
)

_check_source_dirs() {
    echo -e "${YELLOW}Checking source directories...${NC}"
    DIRS_TO_COPY=()
    for dir in "${BMAD_OWNED_DIRS[@]}" "${BMAD_PROMPT_DIRS[@]}" "${BMAD_SHARED_DIRS[@]}"; do
        if [ -d "$SOURCE_DIR/$dir" ]; then
            echo -e "  ${GREEN}✓${NC} Found: $dir"
            DIRS_TO_COPY+=("$dir")
        else
            echo -e "  ${YELLOW}⊘${NC} Not found: $dir (skipping)"
        fi
    done
    echo ""

    if [ ${#DIRS_TO_COPY[@]} -eq 0 ]; then
        echo -e "${RED}✗ No BMAD directories found to copy!${NC}"
        exit 1
    fi
}

_is_owned() {
    local dir="$1"
    for d in "${BMAD_OWNED_DIRS[@]}"; do [ "$dir" = "$d" ] && return 0; done
    return 1
}

_is_prompt() {
    local dir="$1"
    for d in "${BMAD_PROMPT_DIRS[@]}"; do [ "$dir" = "$d" ] && return 0; done
    return 1
}

_copy_owned_dir() {
    local dir="$1"
    [ -d "$DEST_DIR/$dir" ] && rm -rf "$DEST_DIR/$dir"
    echo -e "  ${BLUE}→${NC} Copying files..."
    cp -R "$SOURCE_DIR/$dir" "$DEST_DIR/$dir"
}

_copy_prompt_dir() {
    local dir="$1"

    if [ -d "$DEST_DIR/$dir" ]; then
        echo -e "  ${YELLOW}⚠ $dir already exists and may contain your work.${NC}"
        echo -e "  ${YELLOW}Choose an option:${NC}"
        echo "    1) Overwrite (existing content will be lost)"
        echo "    2) Skip (keep existing, do not copy)"
        read -p "  Your choice [1-2]: " choice
        case $choice in
            1)
                rm -rf "$DEST_DIR/$dir"
                echo -e "  ${BLUE}→${NC} Copying files..."
                cp -R "$SOURCE_DIR/$dir" "$DEST_DIR/$dir"
                ;;
            2)
                echo -e "  ${YELLOW}⊘${NC} Skipped"
                return
                ;;
            *)
                echo -e "  ${RED}✗ Invalid choice. Skipping $dir.${NC}"
                return
                ;;
        esac
    else
        echo -e "  ${BLUE}→${NC} Copying files..."
        cp -R "$SOURCE_DIR/$dir" "$DEST_DIR/$dir"
    fi
}

_copy_shared_dir() {
    local dir="$1"
    mkdir -p "$DEST_DIR/$dir"

    # Remove only existing bmad-* subdirectories
    local removed=0
    for subdir in "$DEST_DIR/$dir"/bmad-*/; do
        [ -d "$subdir" ] || continue
        echo -e "  ${BLUE}→${NC} Removing: $(basename "$subdir")"
        rm -rf "$subdir"
        removed=$((removed + 1))
    done
    [ "$removed" -eq 0 ] && echo -e "  ${BLUE}→${NC} No bmad-* subdirs to remove"

    echo -e "  ${BLUE}→${NC} Copying files..."
    cp -R "$SOURCE_DIR/$dir"/. "$DEST_DIR/$dir/"
}

_do_copy() {
    echo -e "${BLUE}Starting copy operation...${NC}"
    echo ""

    for dir in "${DIRS_TO_COPY[@]}"; do
        echo -e "${YELLOW}Processing: $dir${NC}"

        if _is_owned "$dir"; then
            _copy_owned_dir "$dir"
        elif _is_prompt "$dir"; then
            _copy_prompt_dir "$dir"
        else
            _copy_shared_dir "$dir"
        fi

        echo -e "  ${GREEN}✓${NC} Completed"
        echo ""
    done

    # Copy the cleanup script into scripts/ at the destination
    local clean_script="$SOURCE_DIR/scripts/clean-bmad-config.sh"
    if [ -f "$clean_script" ]; then
        echo -e "${YELLOW}Processing: scripts/clean-bmad-config.sh${NC}"
        mkdir -p "$DEST_DIR/scripts"
        cp "$clean_script" "$DEST_DIR/scripts/clean-bmad-config.sh"
        chmod +x "$DEST_DIR/scripts/clean-bmad-config.sh"
        echo -e "  ${GREEN}✓${NC} Completed"
        echo ""
    fi
}

copy_dirs() {
    _check_source_dirs
    _do_copy
}
