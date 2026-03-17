#!/usr/bin/env bash
# ANSI colors and display helpers
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    local title="$1"
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $(printf '%-54s' "$title")║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
}

print_success_header() {
    local title="$1"
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  $(printf '%-54s' "$title")║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
}
