#!/usr/bin/env bash
# install-bmad.sh — Installs BMAD non-interactively using a config file
# Usage: bash scripts/install-bmad.sh [path/to/install-bmad.config]
#
# Reads the config file and runs: npx bmad-method install --yes
# with all flags derived from the config, so no interactive prompts are needed.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/install-bmad.config}"

source "$SCRIPT_DIR/lib/colors.sh"

# ── Header ────────────────────────────────────────────────────────────────────
print_header "BMAD Auto-Install Script            "
echo ""
echo -e "${GREEN}Repo:   $REPO_DIR${NC}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}Config: $CONFIG_FILE${NC}"
echo ""

# ── Load config ───────────────────────────────────────────────────────────────
source "$CONFIG_FILE"

# ── Resolve auto-detected defaults ────────────────────────────────────────────
if [ -z "$USER_NAME" ]; then
    USER_NAME=$(git -C "$REPO_DIR" config user.name 2>/dev/null || echo "")
fi

if [ -z "$PROJECT_NAME" ]; then
    _remote=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")
    if [ -n "$_remote" ]; then
        PROJECT_NAME=$(basename "$_remote" .git)
    else
        PROJECT_NAME=$(basename "$REPO_DIR")
    fi
fi

if [ -z "$COMMUNICATION_LANGUAGE" ]; then
    _code=""
    if command -v defaults > /dev/null 2>&1; then
        _code=$(defaults read -g AppleLanguages 2>/dev/null \
            | grep -m1 '"' | tr -d ' ",' | cut -d'-' -f1)
    fi
    [ -z "$_code" ] && _code=$(echo "${LANG:-en}" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')
    case "${_code%%-*}" in
        fr) COMMUNICATION_LANGUAGE="French" ;;
        de) COMMUNICATION_LANGUAGE="German" ;;
        es) COMMUNICATION_LANGUAGE="Spanish" ;;
        it) COMMUNICATION_LANGUAGE="Italian" ;;
        pt) COMMUNICATION_LANGUAGE="Portuguese" ;;
        *)  COMMUNICATION_LANGUAGE="English" ;;
    esac
fi

[ -z "$DOCUMENT_OUTPUT_LANGUAGE" ] && DOCUMENT_OUTPUT_LANGUAGE="English"

# ── Build command ─────────────────────────────────────────────────────────────
CMD=(npx bmad-method install --yes --directory "$REPO_DIR")

[ -n "$MODULES" ] && CMD+=(--modules "$MODULES")
[ -n "$TOOLS"   ] && CMD+=(--tools   "$TOOLS")
[ -n "$CHANNEL" ] && CMD+=(--channel "$CHANNEL")

[ -n "$USER_NAME"               ] && CMD+=(--set "core.user_name=$USER_NAME")
[ -n "$PROJECT_NAME"            ] && CMD+=(--set "core.project_name=$PROJECT_NAME")
[ -n "$COMMUNICATION_LANGUAGE"  ] && CMD+=(--set "core.communication_language=$COMMUNICATION_LANGUAGE")
[ -n "$DOCUMENT_OUTPUT_LANGUAGE"] && CMD+=(--set "core.document_output_language=$DOCUMENT_OUTPUT_LANGUAGE")

for cfg in "${MODULE_CONFIG[@]}"; do
    CMD+=(--set "$cfg")
done

[ -n "$PIN_BMB" ] && CMD+=(--pin "bmb=$PIN_BMB")
[ -n "$PIN_CIS" ] && CMD+=(--pin "cis=$PIN_CIS")
[ -n "$PIN_TEA" ] && CMD+=(--pin "tea=$PIN_TEA")
[ -n "$PIN_GDS" ] && CMD+=(--pin "gds=$PIN_GDS")

# ── Preview ───────────────────────────────────────────────────────────────────
echo -e "${YELLOW}Settings:${NC}"
echo -e "  ${BLUE}•${NC} Modules:       ${MODULES:-<default>}"
echo -e "  ${BLUE}•${NC} Tools:         ${TOOLS:-<default>}"
echo -e "  ${BLUE}•${NC} User:          ${USER_NAME}"
echo -e "  ${BLUE}•${NC} Project:       ${PROJECT_NAME}"
echo -e "  ${BLUE}•${NC} Comm. lang:    ${COMMUNICATION_LANGUAGE}"
echo -e "  ${BLUE}•${NC} Output lang:   ${DOCUMENT_OUTPUT_LANGUAGE}"
if [ ${#MODULE_CONFIG[@]} -gt 0 ]; then
    echo -e "  ${BLUE}•${NC} Module config:"
    for cfg in "${MODULE_CONFIG[@]}"; do
        echo -e "    ${GREEN}-${NC} $cfg"
    done
fi
[ -n "$CHANNEL"  ] && echo -e "  ${BLUE}•${NC} Channel:       ${CHANNEL}"
[ -n "$PIN_BMB"  ] && echo -e "  ${BLUE}•${NC} Pin bmb:       ${PIN_BMB}"
[ -n "$PIN_CIS"  ] && echo -e "  ${BLUE}•${NC} Pin cis:       ${PIN_CIS}"
[ -n "$PIN_TEA"  ] && echo -e "  ${BLUE}•${NC} Pin tea:       ${PIN_TEA}"
[ -n "$PIN_GDS"  ] && echo -e "  ${BLUE}•${NC} Pin gds:       ${PIN_GDS}"
echo ""

echo -e "${YELLOW}Command:${NC}"
echo -e "  ${BLUE}${CMD[*]}${NC}"
echo ""

# ── Confirmation ──────────────────────────────────────────────────────────────
read -p "Proceed with installation? [yes/no]: " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${BLUE}Installation cancelled.${NC}"
    exit 0
fi

echo ""

# ── Run installer ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}Running installer...${NC}"
echo ""
"${CMD[@]}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
print_success_header "Installation Completed!             "
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Verify the config: ${YELLOW}_bmad/core/config.yaml${NC}"
echo -e "  2. To copy BMAD to a project: ${YELLOW}pnpm run bmad:copy${NC}"
echo ""
