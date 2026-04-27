#!/usr/bin/env bash
# Adds BMAD entries to .git/info/exclude of the destination repo
# Requires: DEST_DIR, GREEN, YELLOW, NC (from colors.sh)

BMAD_EXCLUDE_PATTERNS=(
    "_bmad/"
    "_bmad-shared/"
    # "_bmad-custom/"
    # "_bmad-output/"
    "scripts/clean-bmad-config.sh"
    ".agents/skills/bmad-*"
)

update_git_exclude() {
    # --git-common-dir always points to the .git of the main repo,
    # even from a worktree — that's where git reads info/exclude
    local git_common_dir
    git_common_dir=$(git -C "$DEST_DIR" rev-parse --git-common-dir 2>/dev/null)

    if [ -z "$git_common_dir" ]; then
        echo -e "  ${YELLOW}⊘${NC} Not a git repository, skipping."
        echo ""
        return
    fi

    # Make the path absolute if necessary
    case "$git_common_dir" in
        /*) : ;;
        *)  git_common_dir="$DEST_DIR/$git_common_dir" ;;
    esac

    local exclude_file="$git_common_dir/info/exclude"
    mkdir -p "$(dirname "$exclude_file")"
    touch "$exclude_file"

    # Ensure there is a trailing newline before adding entries
    if [ -s "$exclude_file" ] && [ "$(tail -c1 "$exclude_file" | wc -l)" -eq 0 ]; then
        echo "" >> "$exclude_file"
    fi

    local added=0
    for entry in "${BMAD_EXCLUDE_PATTERNS[@]}"; do
        if ! grep -qxF "$entry" "$exclude_file" 2>/dev/null; then
            echo "$entry" >> "$exclude_file"
            added=$((added + 1))
        fi
    done

    if [ "$added" -eq 0 ]; then
        echo -e "  ${YELLOW}⊘${NC} .git/info/exclude already up to date"
    else
        echo -e "  ${GREEN}✓${NC} Added $added entr$([ "$added" -eq 1 ] && echo "y" || echo "ies") to $exclude_file"
    fi
    echo ""
}
