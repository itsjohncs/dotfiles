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
        echo "$0 PROJECT"
        echo
        echo "Changes directory to PROJECT."
        return 1
    fi

    local PROJECT_DIR="$HOME/personal/$1"
    cd "$HOME/personal/$1" || return 1
}

## pi: Initializes project.
# shellcheck disable=SC2120
function pi {
    local PROJECT_DIR=""
    if [[ -n $1 ]]; then
        PROJECT_DIR="$HOME/personal/$1"
    else
        local REL
        REL="$(realpath --relative-to "$HOME/personal" "$PWD")"
        if [[ $REL =~ ^([^.][^/]+)(/|$) ]]; then
            PROJECT_DIR="$HOME/personal/${BASH_REMATCH[1]}"
        fi
    fi

    if [[ -z $PROJECT_DIR || ! -d $PROJECT_DIR ]]; then
        if [[ -n $1 ]]; then
            echo "FATAL: Unknown project $1" >&2
        else
            echo "FATAL: Current directory is not within a project" >&2
        fi
        return 1
    fi

    local SUBLIME_PROJECT
    SUBLIME_PROJECT="$(
        find "$PROJECT_DIR" \
            -maxdepth 1 \
            -name "*.sublime-project" \
            -print -quit
    )"
    if [[ -f $SUBLIME_PROJECT ]]; then
        subl --background --project "$SUBLIME_PROJECT"
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
