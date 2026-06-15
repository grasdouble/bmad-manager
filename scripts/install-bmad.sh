#!/usr/bin/env bash
# install-bmad.sh — Installs BMAD non-interactively using a config file
# Usage: bash scripts/install-bmad.sh [--list-options [module]]
#        bash scripts/install-bmad.sh [path/to/install-bmad.config]
#
# Reads the config file and runs: npx bmad-method install --yes
# The action (install/update/quick-update) is auto-detected based on whether _bmad/
# already exists. This script is optimized for new installations.
#
# For module options: bash scripts/install-bmad.sh --list-options [module]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/install-bmad.config}"

source "$SCRIPT_DIR/lib/colors.sh"

# ── Handle --list-options pass-through ─────────────────────────────────────────
if [ "$1" = "--list-options" ]; then
    echo -e "${YELLOW}Available options for BMAD modules:${NC}"
    echo ""
    npx bmad-method@latest install --list-options "${2:-}"
    exit 0
fi

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

# Use shortcuts for core config values (these are historical shortcuts per docs)
[ -n "$USER_NAME"                ] && CMD+=(--user-name "$USER_NAME")
[ -n "$PROJECT_NAME"             ] && CMD+=(--set "core.project_name=$PROJECT_NAME")
[ -n "$DOCUMENT_OUTPUT_LANGUAGE" ] && CMD+=(--set "core.document_output_language=$DOCUMENT_OUTPUT_LANGUAGE")
[ -n "$OUTPUT_FOLDER"            ] && CMD+=(--output-folder "$OUTPUT_FOLDER")

# Note: core values (project_name, communication_language, document_output_language)
# are inherited by all modules via BMAD's default mechanism. No need to repeat them.

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
echo -e "  ${BLUE}•${NC} Output folder: ${OUTPUT_FOLDER}"
if [ ${#MODULE_CONFIG[@]} -gt 0 ]; then
    echo -e "  ${BLUE}•${NC} Module config: (${#MODULE_CONFIG[@]} settings)"
fi
[ -n "$CHANNEL"  ] && echo -e "  ${BLUE}•${NC} Channel:       ${CHANNEL}"
[ -n "$PIN_BMB"  ] && echo -e "  ${BLUE}•${NC} Pin bmb:       ${PIN_BMB}"
[ -n "$PIN_CIS"  ] && echo -e "  ${BLUE}•${NC} Pin cis:       ${PIN_CIS}"
[ -n "$PIN_TEA"  ] && echo -e "  ${BLUE}•${NC} Pin tea:       ${PIN_TEA}"
[ -n "$PIN_GDS"  ] && echo -e "  ${BLUE}•${NC} Pin gds:       ${PIN_GDS}"
echo ""

echo -e "${YELLOW}Command:${NC}"
echo -e "  ${BLUE}${CMD[0]} ... [${#CMD[@]} flags]${NC}"
echo ""

# ── Run installer ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}Running installer...${NC}"
echo ""
"${CMD[@]}"

# ── Post-process YAML files ────────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/lib/fix-bmad-yaml.sh" ]; then
    echo ""
    echo -e "${YELLOW}Fixing YAML formatting...${NC}"
    bash "$SCRIPT_DIR/lib/fix-bmad-yaml.sh" "$REPO_DIR"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
print_success_header "Installation Completed!             "
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Verify the config: ${YELLOW}_bmad/core/config.yaml${NC}"
echo -e "  2. To copy BMAD to a project: ${YELLOW}pnpm run bmad:copy${NC}"
echo -e "  3. For available module options: ${YELLOW}bash scripts/install-bmad.sh --list-options [module]${NC}"
echo ""



