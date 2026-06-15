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
[ -n "$COMMUNICATION_LANGUAGE"   ] && CMD+=(--set "core.communication_language=$COMMUNICATION_LANGUAGE")
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

# ── Move user-scope keys to config.user.toml ───────────────────────────────────
# According to BMAD docs, keys marked [user-scope] should be in config.user.toml
# for user overrides. Manual routing since BMAD doesn't do this automatically.
echo ""
echo -e "${YELLOW}Routing user-scope keys...${NC}"

CONFIG_TOML="$REPO_DIR/_bmad/config.toml"
USER_TOML="$REPO_DIR/_bmad/config.user.toml"

if [ -f "$CONFIG_TOML" ] && [ -f "$USER_TOML" ]; then
    # Use a Python one-liner to move user-scope keys between TOML files
    # This avoids external dependencies while keeping logic simple
    python3 -c "
import re, sys

config_file, user_file = '$CONFIG_TOML', '$USER_TOML'

with open(config_file) as f:
    config = f.read()
with open(user_file) as f:
    user = f.read()

# Extract and move user_name and communication_language from [core]
core_match = re.search(r'\[core\](.*?)(?=\[|$)', config, re.DOTALL)
if core_match:
    core_block = core_match.group(1)
    user_name_match = re.search(r'(user_name = .*?)$', core_block, re.MULTILINE)
    comm_lang_match = re.search(r'(communication_language = .*?)$', core_block, re.MULTILINE)
    
    # Prepare lines to move
    lines_to_move = []
    lines_to_remove_from_config = []
    
    if user_name_match:
        lines_to_move.append(user_name_match.group(1))
        lines_to_remove_from_config.append(user_name_match.group(0))
    
    if comm_lang_match:
        lines_to_move.append(comm_lang_match.group(1))
        lines_to_remove_from_config.append(comm_lang_match.group(0))
    
    # Remove lines from config.toml
    for line in lines_to_remove_from_config:
        config = config.replace(line + '\n', '')
    
    # Add lines to config.user.toml [core] section
    if lines_to_move:
        if '[core]' not in user:
            user = '[core]\n' + user
        
        # Insert after [core]
        user = re.sub(
            r'(\[core\]\n)',
            r'\1' + '\n'.join(lines_to_move) + '\n',
            user
        )

# Write files back
with open(config_file, 'w') as f:
    f.write(config)
with open(user_file, 'w') as f:
    f.write(user)

print('✓ Routed user-scope keys')
"
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



