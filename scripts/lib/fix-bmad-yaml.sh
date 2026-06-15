#!/usr/bin/env bash
# fix-bmad-yaml.sh — Fixes YAML formatting issues in generated BMAD configs
# Converts string booleans ("true"/"false") to proper YAML booleans (true/false)

REPO_DIR="$1"

# Fix boolean values in TEA config
TEA_CONFIG="$REPO_DIR/_bmad/tea/config.yaml"
if [ -f "$TEA_CONFIG" ]; then
    sed -i '' 's/tea_use_playwright_utils: "true"/tea_use_playwright_utils: true/g' "$TEA_CONFIG"
    sed -i '' 's/tea_use_playwright_utils: "false"/tea_use_playwright_utils: false/g' "$TEA_CONFIG"
    sed -i '' 's/tea_use_pactjs_utils: "true"/tea_use_pactjs_utils: true/g' "$TEA_CONFIG"
    sed -i '' 's/tea_use_pactjs_utils: "false"/tea_use_pactjs_utils: false/g' "$TEA_CONFIG"
    sed -i '' 's/tea_capability_probe: "true"/tea_capability_probe: true/g' "$TEA_CONFIG"
    sed -i '' 's/tea_capability_probe: "false"/tea_capability_probe: false/g' "$TEA_CONFIG"
    echo -e "✓ Fixed boolean values in tea/config.yaml"
fi

# Fix visual_tools: convert string representation to proper YAML array format
CIS_CONFIG="$REPO_DIR/_bmad/cis/config.yaml"
if [ -f "$CIS_CONFIG" ]; then
    if grep -q "visual_tools: mermaid,excalidraw,gemini-nano" "$CIS_CONFIG"; then
        # Convert comma-separated string to YAML array
        python3 - "$CIS_CONFIG" << 'PYTHON_EOF'
import sys
import re

config_file = sys.argv[1]

with open(config_file, 'r') as f:
    content = f.read()

# Pattern: visual_tools: mermaid,excalidraw,gemini-nano
pattern = r"visual_tools: ([\w,-]+)"
match = re.search(pattern, content)

if match:
    items_str = match.group(1)
    items = [s.strip() for s in items_str.split(',')]
    
    # Build YAML array format
    yaml_array = "visual_tools:\n"
    for item in items:
        yaml_array += f"  - {item}\n"
    
    # Replace in content
    content = re.sub(pattern, yaml_array.rstrip(), content)
    
    with open(config_file, 'w') as f:
        f.write(content)
PYTHON_EOF
        echo -e "✓ Fixed visual_tools array format in cis/config.yaml"
    fi
fi


