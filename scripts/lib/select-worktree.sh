#!/usr/bin/env bash
# Destination worktree selection
# Expose: DEST_DIR
# Requires: SOURCE_DIR, RED, GREEN, YELLOW, BLUE, NC (from colors.sh)

_get_repo_worktrees() {
    local repo_path="$1"
    local worktrees=()

    if ! git -C "$repo_path" rev-parse --git-dir > /dev/null 2>&1; then
        return 1
    fi

    while IFS= read -r line; do
        worktrees+=("$line")
    done < <(git -C "$repo_path" worktree list --porcelain | grep '^worktree ' | cut -d' ' -f2-)

    AVAILABLE_WORKTREES=("${worktrees[@]}")

    if [ ${#AVAILABLE_WORKTREES[@]} -eq 0 ]; then
        return 1
    fi

    return 0
}

select_destination() {
    # ── Step 1: enter target repo ────────────────────────────────────────────
    echo -e "${YELLOW}Step 1 — Target repository${NC}"
    read -p "Enter the path to the target repo: " TARGET_REPO
    TARGET_REPO="${TARGET_REPO/#\~/$HOME}"
    TARGET_REPO="$(cd "$TARGET_REPO" 2>/dev/null && pwd || echo "$TARGET_REPO")"

    if [ ! -d "$TARGET_REPO" ]; then
        echo -e "${RED}✗ Error: Directory does not exist: $TARGET_REPO${NC}"
        exit 1
    fi

    echo ""

    # ── Step 2: list worktrees → selection ───────────────────────────────────
    echo -e "${YELLOW}Step 2 — Select destination worktree${NC}"

    AVAILABLE_WORKTREES=()
    if _get_repo_worktrees "$TARGET_REPO"; then
        echo -e "${BLUE}Available worktrees for $(basename "$TARGET_REPO"):${NC}"
        for i in "${!AVAILABLE_WORKTREES[@]}"; do
            worktree="${AVAILABLE_WORKTREES[$i]}"
            branch=$(git -C "$worktree" branch --show-current 2>/dev/null || echo "unknown")
            echo -e "  $((i+1))) ${GREEN}$worktree${NC} ${YELLOW}[$branch]${NC}"
        done
        echo ""

        read -p "Select worktree number [1-${#AVAILABLE_WORKTREES[@]}]: " worktree_num

        if ! [[ "$worktree_num" =~ ^[0-9]+$ ]] || [ "$worktree_num" -lt 1 ] || [ "$worktree_num" -gt ${#AVAILABLE_WORKTREES[@]} ]; then
            echo -e "${RED}✗ Invalid selection. Operation cancelled.${NC}"
            exit 1
        fi

        DEST_DIR="${AVAILABLE_WORKTREES[$((worktree_num-1))]}"
        echo -e "${GREEN}Selected:${NC} $DEST_DIR"
        echo ""
    else
        echo -e "${YELLOW}⚠ No git worktrees found. Using the repo root directly.${NC}"
        DEST_DIR="$TARGET_REPO"
        echo -e "${GREEN}Destination:${NC} $DEST_DIR"
        echo ""
    fi

    # ── Validations ──────────────────────────────────────────────────────────
    if [ ! -d "$DEST_DIR" ]; then
        echo -e "${RED}✗ Error: Destination directory does not exist: $DEST_DIR${NC}"
        exit 1
    fi

    if [ "$SOURCE_DIR" = "$DEST_DIR" ]; then
        echo -e "${RED}✗ Error: Source and destination are the same!${NC}"
        exit 1
    fi

    echo -e "${GREEN}Destination:${NC} $DEST_DIR"
    echo ""
}
