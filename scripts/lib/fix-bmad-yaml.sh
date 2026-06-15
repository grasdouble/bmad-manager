#!/usr/bin/env bash
# fix-bmad-yaml.sh — Fixes formatting issues in generated BMAD configs
# - Converts string booleans ("true"/"false") to proper booleans (true/false)
# - Converts visual_tools string to YAML array
# - Replaces environment variable placeholders with actual values
# - Adds "# Core Configuration Values" comment section before core keys
# Works on both TOML and YAML config files

REPO_DIR="$1"

# ─────────────────────────────────────────────────────────────────────────────
# Add "# Core Configuration Values" comment section before core keys in modules
# and reorder them to match official BMAD output order
# ─────────────────────────────────────────────────────────────────────────────
add_core_section_comment_and_reorder() {
    local file="$1"
    # Find if this file has core keys (user_name, project_name, etc.)
    if grep -q "^user_name:" "$file"; then
        # Extract core keys
        local user_name=$(grep "^user_name:" "$file")
        local project_name=$(grep "^project_name:" "$file")
        local communication_language=$(grep "^communication_language:" "$file")
        local document_output_language=$(grep "^document_output_language:" "$file")
        local output_folder=$(grep "^output_folder:" "$file")
        
        # Remove all core key lines
        sed -i.bak \
            -e '/^user_name:/d' \
            -e '/^project_name:/d' \
            -e '/^communication_language:/d' \
            -e '/^document_output_language:/d' \
            -e '/^output_folder:/d' \
            "$file"
        rm -f "${file}.bak"
        
        # Add them back in the correct order with comment using Python
        # Use environment variables to safely pass values to Python
        export PYTHON_FILE="$file"
        export PYTHON_USER_NAME="$user_name"
        export PYTHON_PROJECT_NAME="$project_name"
        export PYTHON_COMM_LANG="$communication_language"
        export PYTHON_DOC_LANG="$document_output_language"
        export PYTHON_OUTPUT_FOLDER="$output_folder"
        
        python3 << 'PYTHON_EOF'
import os

file_path = os.environ.get('PYTHON_FILE')
user_name_line = os.environ.get('PYTHON_USER_NAME', '')
project_name_line = os.environ.get('PYTHON_PROJECT_NAME', '')
comm_lang_line = os.environ.get('PYTHON_COMM_LANG', '')
doc_lang_line = os.environ.get('PYTHON_DOC_LANG', '')
output_folder_line = os.environ.get('PYTHON_OUTPUT_FOLDER', '')

with open(file_path, 'r') as f:
    lines = f.readlines()

# Find last non-empty line
last_idx = len(lines) - 1
while last_idx >= 0 and lines[last_idx].strip() == '':
    last_idx -= 1

# Build the core section
core_lines = []
core_lines.append('\n# Core Configuration Values\n')
if user_name_line.strip():
    core_lines.append(user_name_line + '\n')
if project_name_line.strip():
    core_lines.append(project_name_line + '\n')
if comm_lang_line.strip():
    core_lines.append(comm_lang_line + '\n')
if doc_lang_line.strip():
    core_lines.append(doc_lang_line + '\n')
if output_folder_line.strip():
    core_lines.append(output_folder_line + '\n')

# Insert after last non-empty line
if last_idx >= 0:
    for i, line in enumerate(core_lines):
        lines.insert(last_idx + 1 + i, line)

with open(file_path, 'w') as f:
    f.writelines(lines)
PYTHON_EOF
    fi
}

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
# Remove core keys from module sections in config.toml
# (these should only be in [core], not duplicated in [modules.X])
# ─────────────────────────────────────────────────────────────────────────────
remove_core_keys_from_module_sections() {
    local file="$1"
    export REMOVE_CORE_TOML_FILE="$file"
    
    python3 << 'PYTHON_EOF'
import os
import re

file_path = os.environ.get('REMOVE_CORE_TOML_FILE')

# Core keys that should only be in [core], never in [modules.*]
core_keys = {'user_name', 'project_name', 'communication_language', 'document_output_language', 'output_folder'}

with open(file_path, 'r') as f:
    lines = f.readlines()

output = []
in_module_section = False

for line in lines:
    # Check if we're entering a [modules.* section
    if line.startswith('[modules.'):
        in_module_section = True
        output.append(line)
    # Check if we're entering a non-module section (ends the module section)
    elif line.startswith('[') and not line.startswith('[modules.'):
        in_module_section = False
        output.append(line)
    # In a module section, check if this line is a core key
    elif in_module_section:
        key_match = re.match(r'^(\w+)\s*=', line.strip())
        if key_match and key_match.group(1) in core_keys:
            # Skip this line (it's a core key that shouldn't be here)
            continue
        output.append(line)
    else:
        output.append(line)

with open(file_path, 'w') as f:
    f.writelines(output)
PYTHON_EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Add core configuration values section to module YAML files
# These files should contain all core values for context and persistence
# ─────────────────────────────────────────────────────────────────────────────
add_core_section_to_module_yaml() {
    local file="$1"
    local repo_dir="$2"
    
    # If core values section already exists, skip (already has them)
    if grep -q "^# Core Configuration Values" "$file"; then
        return
    fi
    
    # Read core values from the core config.yaml
    CORE_CONFIG="$repo_dir/_bmad/core/config.yaml"
    if [ ! -f "$CORE_CONFIG" ]; then
        return
    fi
    
    export CORE_YAML_FILE="$CORE_CONFIG"
    export MODULE_YAML_FILE="$file"
    
    python3 << 'PYTHON_EOF'
import os
import re

core_file = os.environ.get('CORE_YAML_FILE')
module_file = os.environ.get('MODULE_YAML_FILE')

# Read core config to extract core values
core_values = {}
with open(core_file, 'r') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        # Parse YAML key: value
        match = re.match(r'^(\w+):\s*(.+)$', line)
        if match:
            key = match.group(1)
            value = match.group(2)
            # Only extract core keys
            if key in ['user_name', 'project_name', 'communication_language', 'document_output_language', 'output_folder']:
                core_values[key] = f"{key}: {value}"

# Read module YAML
with open(module_file, 'r') as f:
    lines = f.readlines()

# Remove any standalone core key lines that exist before the comment (duplicates from BMAD's --set behavior)
core_keys_set = {'user_name', 'project_name', 'communication_language', 'document_output_language', 'output_folder'}
cleaned_lines = []
for line in lines:
    key_match = re.match(r'^(\w+):\s*', line.strip())
    # Skip if it's a core key (we'll add them all together below)
    if key_match and key_match.group(1) in core_keys_set:
        continue
    cleaned_lines.append(line)

lines = cleaned_lines

# Find where to insert (at the end, before any trailing whitespace)
insert_idx = len(lines)
while insert_idx > 0 and lines[insert_idx - 1].strip() == '':
    insert_idx -= 1

# Build core section
core_section = []
core_section.append('\n# Core Configuration Values\n')
for key in ['user_name', 'project_name', 'communication_language', 'document_output_language', 'output_folder']:
    if key in core_values:
        core_section.append(core_values[key] + '\n')

# Insert core section
if core_section:
    for i, line in enumerate(core_section):
        lines.insert(insert_idx + i, line)

# Write back
with open(module_file, 'w') as f:
    f.writelines(lines)
PYTHON_EOF
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
    # Remove duplicated core keys from module sections
    remove_core_keys_from_module_sections "$CONFIG_TOML"
    echo "✓ Fixed config.toml (booleans, arrays, env vars)"
fi

# Fix module YAML files
for module in bmm bmb tea cis gds; do
    MODULE_CONFIG="$REPO_DIR/_bmad/$module/config.yaml"
    if [ -f "$MODULE_CONFIG" ]; then
        fix_yaml_booleans "$MODULE_CONFIG"
        # Add core configuration section if not present
        add_core_section_to_module_yaml "$MODULE_CONFIG" "$REPO_DIR"
    fi
done

# Fix TEA yaml booleans (already done above, but kept for clarity)
TEA_CONFIG="$REPO_DIR/_bmad/tea/config.yaml"
if [ -f "$TEA_CONFIG" ]; then
    echo "✓ Fixed boolean values in tea/config.yaml"
fi

# Fix CIS visual_tools array
CIS_CONFIG="$REPO_DIR/_bmad/cis/config.yaml"
if [ -f "$CIS_CONFIG" ]; then
    fix_yaml_visual_tools "$CIS_CONFIG"
    echo "✓ Fixed visual_tools array format in cis/config.yaml"
fi

