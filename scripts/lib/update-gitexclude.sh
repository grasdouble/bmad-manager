#!/usr/bin/env bash
# Adds or removes BMAD entries in .git/info/exclude of the destination repo
# Requires: DEST_DIR, GREEN, YELLOW, BLUE, NC (from colors.sh)

source "$(dirname "${BASH_SOURCE[0]}")/bmad-patterns.sh"

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

# remove_git_exclude TARGET_DIR
#   Removes BMAD_EXCLUDE_PATTERNS entries from .git/info/exclude of TARGET_DIR.
#   Uses | as sed delimiter to avoid conflicts with / in paths (BSD sed / macOS compatible).
remove_git_exclude() {
    local target_dir="$1"
    local git_dir
    git_dir=$(git -C "$target_dir" rev-parse --git-common-dir 2>/dev/null)

    if [ -z "$git_dir" ]; then
        echo -e "  ${YELLOW}⊘${NC} Not a git repository, skipping"
        return
    fi

    case "$git_dir" in
        /*) : ;;
        *)  git_dir="$target_dir/$git_dir" ;;
    esac

    local exclude_file="$git_dir/info/exclude"
    if [ ! -f "$exclude_file" ]; then
        echo -e "  ${YELLOW}⊘${NC} .git/info/exclude not found, skipping"
        return
    fi

    local before after removed
    before=$(wc -l < "$exclude_file")
    for pattern in "${BMAD_EXCLUDE_PATTERNS[@]}"; do
        local escaped
        escaped=$(printf '%s\n' "$pattern" | sed 's/[.[\*^$|]/\\&/g')
        sed -i.bak "\\|^${escaped}$|d" "$exclude_file" && rm -f "$exclude_file.bak"
    done
    after=$(wc -l < "$exclude_file")
    removed=$((before - after))

    if [ "$removed" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Removed $removed entr$([ "$removed" -eq 1 ] && echo "y" || echo "ies") from .git/info/exclude"
    else
        echo -e "  ${YELLOW}⊘${NC} No BMAD entries found in .git/info/exclude"
    fi
}
