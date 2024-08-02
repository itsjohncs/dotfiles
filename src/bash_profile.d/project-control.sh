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
        if [[ -d "$HOME/personal/$REPO_NAME" ]]; then
            echo "FATAL: Project with name \`$REPO_NAME\` already exists." >&2
            return 1
        else
            git clone "$1" "$HOME/personal/$REPO_NAME" && cd "$HOME/personal/$REPO_NAME" || return 1
        fi
    else
        cd "$HOME/personal/$1" || return 1
    fi
}

## pi: Initializes project.
# shellcheck disable=SC2120
function pi {
    local PROJECT_DIR=""
    local REL
    REL="$(realpath --relative-to "$HOME/personal" "$PWD")"
    if [[ $REL =~ ^([^.][^/]+)(/|$) ]]; then
        PROJECT_DIR="$HOME/personal/${BASH_REMATCH[1]}"
    fi

    if [[ -z $PROJECT_DIR || ! -d $PROJECT_DIR ]]; then
        echo "FATAL: Current directory is not within a project" >&2
        return 1
    fi

    SETUP_SCRIPT="$PROJECT_DIR/.dotfiles-setup.sh"
    if [[ -f $SETUP_SCRIPT ]]; then
        # shellcheck source=/dev/null
        source "$SETUP_SCRIPT"
    else
        echo "WARNING: $SETUP_SCRIPT not found" >&2
    fi

    return 0
}
