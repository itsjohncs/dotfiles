PROJECT_ROOTS=("$HOME/personal" "$HOME/elicit")

## pd: Changes directory to project or clones a new one.
function pd {
    if [[ -z $1 ]]; then
        local CURRENT_PROJECT_ROOT
        CURRENT_PROJECT_ROOT="$(git rev-parse --show-superproject-working-tree 2>/dev/null)"
        if [[ -z $CURRENT_PROJECT_ROOT ]]; then
            CURRENT_PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
        fi

        if [[ -z $CURRENT_PROJECT_ROOT ]]; then
            echo "FATAL: You are not in a git repo." >&2
            return 1
        fi

        cd "$CURRENT_PROJECT_ROOT" || return 1
    elif [[ $1 =~ ^(https?://|git@) ]]; then
        local REPO_NAME
        REPO_NAME=$(basename "$1" .git)

        local EXISTING_ROOTS=()
        for ROOT in "${PROJECT_ROOTS[@]}"; do
            if [[ -d "$ROOT/$REPO_NAME" ]]; then
                EXISTING_ROOTS+=("$ROOT")
            fi
        done

        if [[ ${#EXISTING_ROOTS[@]} -gt 1 ]]; then
            echo "FATAL: Project \`$REPO_NAME\` exists in multiple locations: ${EXISTING_ROOTS[*]}" >&2
            return 1
        elif [[ ${#EXISTING_ROOTS[@]} -eq 1 ]]; then
            echo "FATAL: Project with name \`$REPO_NAME\` already exists at ${EXISTING_ROOTS[0]}/$REPO_NAME" >&2
            return 1
        fi

        local AVAILABLE_ROOTS=()
        for ROOT in "${PROJECT_ROOTS[@]}"; do
            if [[ -d $ROOT ]]; then
                AVAILABLE_ROOTS+=("$ROOT")
            fi
        done

        if [[ ${#AVAILABLE_ROOTS[@]} -eq 0 ]]; then
            echo "FATAL: No project directories exist. Create one of: ${PROJECT_ROOTS[*]}" >&2
            return 1
        elif [[ ${#AVAILABLE_ROOTS[@]} -eq 1 ]]; then
            TARGET_ROOT="${AVAILABLE_ROOTS[0]}"
        else
            echo "Where should this project be cloned?"
            select TARGET_ROOT in "${AVAILABLE_ROOTS[@]}"; do
                if [[ -n $TARGET_ROOT ]]; then
                    break
                fi
            done
        fi

        git clone "$1" "$TARGET_ROOT/$REPO_NAME" && cd "$TARGET_ROOT/$REPO_NAME" || return 1
    else
        local FOUND_ROOTS=()
        for ROOT in "${PROJECT_ROOTS[@]}"; do
            if [[ -d "$ROOT/$1" ]]; then
                FOUND_ROOTS+=("$ROOT")
            fi
        done

        if [[ ${#FOUND_ROOTS[@]} -eq 0 ]]; then
            echo "FATAL: Project \`$1\` not found in any of: ${PROJECT_ROOTS[*]}" >&2
            return 1
        elif [[ ${#FOUND_ROOTS[@]} -gt 1 ]]; then
            echo "FATAL: Project \`$1\` exists in multiple locations: ${FOUND_ROOTS[*]}" >&2
            return 1
        fi

        cd "${FOUND_ROOTS[0]}/$1" || return 1
    fi
}

## pi: Initializes project.
# shellcheck disable=SC2120
function pi {
    local FOUND_DIRS=()
    local REL PROJECT_NAME

    for ROOT in "${PROJECT_ROOTS[@]}"; do
        REL="$(realpath --relative-to "$ROOT" "$PWD" 2>/dev/null)"
        if [[ $REL =~ ^([^.][^/]+)(/|$) ]]; then
            PROJECT_NAME="${BASH_REMATCH[1]}"
            if [[ -d "$ROOT/$PROJECT_NAME" ]]; then
                FOUND_DIRS+=("$ROOT/$PROJECT_NAME")
            fi
        fi
    done

    if [[ ${#FOUND_DIRS[@]} -eq 0 ]]; then
        echo "FATAL: Current directory is not within a project" >&2
        return 1
    elif [[ ${#FOUND_DIRS[@]} -gt 1 ]]; then
        echo "FATAL: Current directory matches multiple projects: ${FOUND_DIRS[*]}" >&2
        return 1
    fi

    local PROJECT_DIR="${FOUND_DIRS[0]}"
    local SETUP_SCRIPT="$PROJECT_DIR/.dotfiles-setup.sh"
    if [[ -f $SETUP_SCRIPT ]]; then
        # shellcheck source=/dev/null
        source "$SETUP_SCRIPT"
    else
        echo "WARNING: $SETUP_SCRIPT not found" >&2
    fi

    return 0
}
