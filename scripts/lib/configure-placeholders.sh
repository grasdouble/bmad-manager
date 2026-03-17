#!/usr/bin/env bash
# Remplacement des placeholders dans les fichiers copiés
# Requires: DEST_DIR, YELLOW, GREEN, NC (depuis colors.sh)

# Convertit un code langue ISO (fr, en, fr-FR, ...) en nom lisible
_lang_code_to_name() {
    local code="${1%%-*}"  # Garder seulement la partie avant le tiret (fr-FR → fr)
    case "$code" in
        fr) echo "French" ;;
        en) echo "English" ;;
        de) echo "German" ;;
        es) echo "Spanish" ;;
        it) echo "Italian" ;;
        pt) echo "Portuguese" ;;
        nl) echo "Dutch" ;;
        ja) echo "Japanese" ;;
        zh) echo "Chinese" ;;
        ko) echo "Korean" ;;
        *)  echo "English" ;;
    esac
}

# Détecte la langue système (macOS d'abord, puis $LANG)
_detect_system_language() {
    local code=""

    # macOS : lire la première langue des préférences
    if command -v defaults > /dev/null 2>&1; then
        code=$(defaults read -g AppleLanguages 2>/dev/null \
            | grep -m1 '"' \
            | tr -d ' ",' \
            | cut -d'-' -f1)
    fi

    # Fallback : variable $LANG (ex: fr_FR.UTF-8)
    if [ -z "$code" ] && [ -n "$LANG" ]; then
        code=$(echo "$LANG" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')
    fi

    _lang_code_to_name "$code"
}

configure_placeholders() {
    # ── Calcul des valeurs par défaut ─────────────────────────────────────────
    local default_username
    default_username=$(git -C "$DEST_DIR" config user.name 2>/dev/null || echo "")

    local default_project
    local _remote_url
    _remote_url=$(git -C "$DEST_DIR" remote get-url origin 2>/dev/null)
    if [ -n "$_remote_url" ]; then
        # Fonctionne avec SSH (git@github.com:org/repo.git) et HTTPS (https://github.com/org/repo.git)
        default_project=$(basename "$_remote_url" .git)
    else
        default_project=$(basename "$DEST_DIR")
    fi

    local default_lang
    default_lang=$(_detect_system_language)

    # ── Prompts avec valeurs par défaut affichées ─────────────────────────────
    echo -e "${YELLOW}These values will replace the placeholders in all copied config files.${NC}"
    echo -e "${YELLOW}Press Enter to use the default value shown in brackets.${NC}"
    echo ""

    read -p "Username            [$default_username]: " CFG_USERNAME
    read -p "Communication lang  [$default_lang]: "    CFG_COMM_LANG
    read -p "Output language     [English]: "           CFG_OUT_LANG
    read -p "Project name        [$default_project]: " CFG_PROJECT
    echo ""

    # Appliquer les defaults si l'utilisateur a juste appuyé Entrée
    [ -z "$CFG_USERNAME" ]  && CFG_USERNAME="$default_username"
    [ -z "$CFG_COMM_LANG" ] && CFG_COMM_LANG="$default_lang"
    [ -z "$CFG_OUT_LANG" ]  && CFG_OUT_LANG="English"
    [ -z "$CFG_PROJECT" ]   && CFG_PROJECT="$default_project"

    # ── Tableaux parallèles compatibles bash 3.2 ─────────────────────────────
    PLACEHOLDER_KEYS=()
    PLACEHOLDER_VALS=()
    if [ -n "$CFG_USERNAME" ];  then PLACEHOLDER_KEYS+=("BMAD_MANAGER_USERNAME");              PLACEHOLDER_VALS+=("$CFG_USERNAME");  fi
    if [ -n "$CFG_COMM_LANG" ]; then PLACEHOLDER_KEYS+=("BMAD_MANAGER_COMMUNICATION_LANGUAGE"); PLACEHOLDER_VALS+=("$CFG_COMM_LANG"); fi
    if [ -n "$CFG_OUT_LANG" ];  then PLACEHOLDER_KEYS+=("BMAD_MANAGER_OUTPUT_LANGUAGE");        PLACEHOLDER_VALS+=("$CFG_OUT_LANG");  fi
    if [ -n "$CFG_PROJECT" ];   then PLACEHOLDER_KEYS+=("BMAD_MANAGER_PROJECT_NAME");            PLACEHOLDER_VALS+=("$CFG_PROJECT");   fi

    if [ ${#PLACEHOLDER_KEYS[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}⊘${NC} No values to apply, skipping placeholder replacement."
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
