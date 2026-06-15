#!/usr/bin/env bash
# fix-bmad-yaml.sh — Fixes formatting issues in generated BMAD configs
# - Converts string booleans ("true"/"false") to proper booleans (true/false)
# - Converts visual_tools string to YAML array
# - Replaces environment variable placeholders with actual values
# Works on both TOML and YAML config files

REPO_DIR="$1"

# ─────────────────────────────────────────────────────────────────────────────
# Helper: Replace environment variable placeholders with actual values
# Used in config.toml which may contain BMAD_MANAGER_* placeholders
# ─────────────────────────────────────────────────────────────────────────────
replace_env_vars() {
    local file="$1"
    # Read config to get actual values (sourcing config file may not work in subshell)
    local config_file="${REPO_DIR}/../scripts/install-bmad.config"
    
    if [ -f "$config_file" ]; then
        # Extract values from config
        PROJECT_NAME=$(grep "^PROJECT_NAME=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        USER_NAME=$(grep "^USER_NAME=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        COMMUNICATION_LANGUAGE=$(grep "^COMMUNICATION_LANGUAGE=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        DOCUMENT_OUTPUT_LANGUAGE=$(grep "^DOCUMENT_OUTPUT_LANGUAGE=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        
        # Replace placeholders with actual values (sed escaping needed for paths)
        sed -i '' \
            "s/\"BMAD_MANAGER_PROJECT_NAME\"/\"${PROJECT_NAME}/g" \
            "s/\"BMAD_MANAGER_USER_NAME\"/\"${USER_NAME}/g" \
            "s/\"BMAD_MANAGER_COMMUNICATION_LANGUAGE\"/\"${COMMUNICATION_LANGUAGE}/g" \
            "s/\"BMAD_MANAGER_OUTPUT_LANGUAGE\"/\"${DOCUMENT_OUTPUT_LANGUAGE}/g" \
            "$file"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Fix TOML config.toml booleans
# ─────────────────────────────────────────────────────────────────────────────
fix_toml_booleans() {
    local file="$1"
    sed -i '' \
        -e 's/tea_use_playwright_utils = "true"/tea_use_playwright_utils = true/g' \
        -e 's/tea_use_playwright_utils = "false"/tea_use_playwright_utils = false/g' \
        -e 's/tea_use_pactjs_utils = "true"/tea_use_pactjs_utils = true/g' \
        -e 's/tea_use_pactjs_utils = "false"/tea_use_pactjs_utils = false/g' \
        -e 's/tea_capability_probe = "true"/tea_capability_probe = true/g' \
        -e 's/tea_capability_probe = "false"/tea_capability_probe = false/g' \
        -e 's/tea_pact_mcp = "true"/tea_pact_mcp = true/g' \
        -e 's/tea_pact_mcp = "false"/tea_pact_mcp = false/g' \
        -e 's/tea_browser_automation = "true"/tea_browser_automation = true/g' \
        -e 's/tea_browser_automation = "false"/tea_browser_automation = false/g' \
        "$file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Fix YAML config booleans
# ─────────────────────────────────────────────────────────────────────────────
fix_yaml_booleans() {
    local file="$1"
    sed -i '' \
        -e 's/tea_use_playwright_utils: "true"/tea_use_playwright_utils: true/g' \
        -e 's/tea_use_playwright_utils: "false"/tea_use_playwright_utils: false/g' \
        -e 's/tea_use_pactjs_utils: "true"/tea_use_pactjs_utils: true/g' \
        -e 's/tea_use_pactjs_utils: "false"/tea_use_pactjs_utils: false/g' \
        -e 's/tea_capability_probe: "true"/tea_capability_probe: true/g' \
        -e 's/tea_capability_probe: "false"/tea_capability_probe: false/g' \
        -e 's/tea_pact_mcp: "true"/tea_pact_mcp: true/g' \
        -e 's/tea_pact_mcp: "false"/tea_pact_mcp: false/g' \
        -e 's/tea_browser_automation: "true"/tea_browser_automation: true/g' \
        -e 's/tea_browser_automation: "false"/tea_browser_automation: false/g' \
        "$file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Fix visual_tools: TOML version (convert string to array)
# ─────────────────────────────────────────────────────────────────────────────
fix_toml_visual_tools() {
    local file="$1"
    python3 -c "
import re

with open('$file', 'r') as f:
    content = f.read()

# Convert TOML visual_tools string to array format
# From: visual_tools = \"mermaid,excalidraw,gemini-nano\"
# To:   visual_tools = [\"mermaid\", \"excalidraw\", \"gemini-nano\"]
content = re.sub(
    r'visual_tools = \"([^\"]*)\"',
    lambda m: 'visual_tools = [' + ', '.join('\"' + tool.strip() + '\"' for tool in m.group(1).split(',')) + ']',
    content
)

with open('$file', 'w') as f:
    f.write(content)
"
}

# ─────────────────────────────────────────────────────────────────────────────
# Fix visual_tools: YAML version (convert string to array)
# ─────────────────────────────────────────────────────────────────────────────
fix_yaml_visual_tools() {
    local file="$1"
    python3 -c "
import re

with open('$file', 'r') as f:
    content = f.read()

# Convert YAML visual_tools string to array format
# From: visual_tools: mermaid,excalidraw,gemini-nano
# To:   visual_tools:
#         - mermaid
#         - excalidraw
#         - gemini-nano
pattern = r'visual_tools: ([\w,-]+)'
match = re.search(pattern, content)

if match:
    items_str = match.group(1)
    items = [s.strip() for s in items_str.split(',')]
    yaml_array = 'visual_tools:\\n' + '\\n'.join(f'  - {item}' for item in items)
    content = re.sub(pattern, yaml_array, content)
    
with open('$file', 'w') as f:
    f.write(content)
"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main: Process all config files
# ─────────────────────────────────────────────────────────────────────────────

# Fix config.toml (booleans, arrays, env vars)
CONFIG_TOML="$REPO_DIR/_bmad/config.toml"
if [ -f "$CONFIG_TOML" ]; then
    fix_toml_booleans "$CONFIG_TOML"
    fix_toml_visual_tools "$CONFIG_TOML"
    replace_env_vars "$CONFIG_TOML"
    echo "✓ Fixed config.toml (booleans, arrays, env vars)"
fi

# Fix TEA yaml booleans
TEA_CONFIG="$REPO_DIR/_bmad/tea/config.yaml"
if [ -f "$TEA_CONFIG" ]; then
    fix_yaml_booleans "$TEA_CONFIG"
    echo "✓ Fixed boolean values in tea/config.yaml"
fi

# Fix CIS visual_tools array
CIS_CONFIG="$REPO_DIR/_bmad/cis/config.yaml"
if [ -f "$CIS_CONFIG" ]; then
    fix_yaml_visual_tools "$CIS_CONFIG"
    echo "✓ Fixed visual_tools array format in cis/config.yaml"
fi

