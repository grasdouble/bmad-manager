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

# ── Build command ─────────────────────────────────────────────────────────────
CMD=(npx bmad-method install --yes --directory "$REPO_DIR")

[ -n "$MODULES" ] && CMD+=(--modules "$MODULES")
[ -n "$TOOLS"   ] && CMD+=(--tools   "$TOOLS")
[ -n "$CHANNEL" ] && CMD+=(--channel "$CHANNEL")

# Pass core values for core module + every installed module
_all_modules="core${MODULES:+,$MODULES}"
IFS=',' read -ra _mod_list <<< "$_all_modules"
for _mod in "${_mod_list[@]}"; do
    [ -n "$USER_NAME"                ] && CMD+=(--set "${_mod}.user_name=$USER_NAME")
    [ -n "$PROJECT_NAME"             ] && CMD+=(--set "${_mod}.project_name=$PROJECT_NAME")
    [ -n "$COMMUNICATION_LANGUAGE"   ] && CMD+=(--set "${_mod}.communication_language=$COMMUNICATION_LANGUAGE")
    [ -n "$DOCUMENT_OUTPUT_LANGUAGE" ] && CMD+=(--set "${_mod}.document_output_language=$DOCUMENT_OUTPUT_LANGUAGE")
done

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
