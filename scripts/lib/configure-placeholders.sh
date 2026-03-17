#!/usr/bin/env bash
# Remplacement des placeholders dans les fichiers copiés
# Requires: DEST_DIR, YELLOW, GREEN, NC (depuis colors.sh)

configure_placeholders() {
    echo -e "${YELLOW}These values will replace the placeholders in all copied config files.${NC}"
    echo -e "${YELLOW}Press Enter to keep the placeholder as-is.${NC}"
    echo ""

    read -p "Username            [BMAD_MANAGER_USERNAME]: "             CFG_USERNAME
    read -p "Communication lang  [BMAD_MANAGER_COMMUNICATION_LANGUAGE]: " CFG_COMM_LANG
    read -p "Output language     [BMAD_MANAGER_OUTPUT_LANGUAGE]: "      CFG_OUT_LANG
    read -p "Project name        [BMAD_MANAGER_PROJECT_NAME]: "         CFG_PROJECT
    echo ""

    # Tableaux parallèles compatibles bash 3.2 (pas de declare -A)
    PLACEHOLDER_KEYS=()
    PLACEHOLDER_VALS=()
    if [ -n "$CFG_USERNAME" ];  then PLACEHOLDER_KEYS+=("BMAD_MANAGER_USERNAME");              PLACEHOLDER_VALS+=("$CFG_USERNAME");  fi
    if [ -n "$CFG_COMM_LANG" ]; then PLACEHOLDER_KEYS+=("BMAD_MANAGER_COMMUNICATION_LANGUAGE"); PLACEHOLDER_VALS+=("$CFG_COMM_LANG"); fi
    if [ -n "$CFG_OUT_LANG" ];  then PLACEHOLDER_KEYS+=("BMAD_MANAGER_OUTPUT_LANGUAGE");        PLACEHOLDER_VALS+=("$CFG_OUT_LANG");  fi
    if [ -n "$CFG_PROJECT" ];   then PLACEHOLDER_KEYS+=("BMAD_MANAGER_PROJECT_NAME");            PLACEHOLDER_VALS+=("$CFG_PROJECT");   fi

    if [ ${#PLACEHOLDER_KEYS[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}⊘${NC} No values entered, skipping placeholder replacement."
        echo ""
        return
    fi

    echo -e "${YELLOW}Applying configuration...${NC}"

    PATCHED_FILES=()
    for i in "${!PLACEHOLDER_KEYS[@]}"; do
        local placeholder="${PLACEHOLDER_KEYS[$i]}"
        local value="${PLACEHOLDER_VALS[$i]}"
        while IFS= read -r file; do
            sed -i.bak "s|$placeholder|$value|g" "$file"
            rm -f "${file}.bak"
            [[ " ${PATCHED_FILES[*]} " != *" $file "* ]] && PATCHED_FILES+=("$file")
        done < <(grep -rl "$placeholder" "$DEST_DIR" 2>/dev/null)
    done

    if [ ${#PATCHED_FILES[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}⊘${NC} No placeholders found (skipping)"
    else
        for file in "${PATCHED_FILES[@]}"; do
            echo -e "  ${GREEN}✓${NC} ${file#$DEST_DIR/}"
        done
    fi
    echo ""
}
