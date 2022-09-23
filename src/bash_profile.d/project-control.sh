## p: Opens dev environment for project.
function p {
    if [[ $# -eq 0 ]]; then
        pi
        return $?
    elif [[ $# -ne 1 ]]; then
        echo "$0 PROJECT"
        echo
        echo "Opens and prepares dev environment for PROJECT."
        return 1
    fi

    pd "$1" || return 1
    local PROJECT_DIR="$PWD"

    if ! pi 2> /dev/null; then
        echo "WARNING: Unexpected error while initializing project" >&2
    fi
}

## pd: Changes directory to project.
function pd {
    if [[ -z $1 ]]; then
        local CURRENT_PROJECT_ROOT
        CURRENT_PROJECT_ROOT="$(git rev-parse --show-superproject-working-tree 2> /dev/null)"
        if [[ -z $CURRENT_PROJECT_ROOT ]]; then
            CURRENT_PROJECT_ROOT="$(git rev-parse --show-toplevel 2> /dev/null)"
        fi

        if [[ -z $CURRENT_PROJECT_ROOT ]]; then
            echo "FATAL: You are not in a git repo." >&2
            return 1
        fi

        cd "$CURRENT_PROJECT_ROOT" || return 1
    else
        local PROJECT_DIR="$HOME/personal/$1"
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
