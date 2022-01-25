## p: Opens dev environment for project.
function p {
    if [[ $# -ne 1 ]]; then
        echo "$0 PROJECT"
        echo
        echo "Opens and prepares dev environment for PROJECT."
        exit 1
    fi

    PROJECT_DIR="$HOME/personal/$1"
    if [[ ! -d $PROJECT_DIR ]]; then
        echo "FATAL: Unknown project $1"
        exit 1
    fi

    SUBLIME_WORKSPACE="$(
        find "$PROJECT_DIR" \
            -maxdepth 1 \
            -name "*.sublime-workspace" \
            -print -quit
    )"
    if [[ -f $SUBLIME_WORKSPACE ]]; then
        subl "$SUBLIME_WORKSPACE"
    else
        subl "$PROJECT_DIR"
    fi

    SETUP_SCRIPT="$PROJECT_DIR/.dotfiles-setup.sh"
    if [[ -f $SETUP_SCRIPT ]]; then
        # shellcheck source=/dev/null
        source "$SETUP_SCRIPT"
    fi

    cd "$PROJECT_DIR" || return $?
}

## pd: Changes directory to project.
function pd {
    PROJECT_DIR="$HOME/personal/$1"

    cd "$PROJECT_DIR" || return 1

    SETUP_SCRIPT="$PROJECT_DIR/.dotfiles-setup.sh"
    if [[ -f $SETUP_SCRIPT ]]; then
        # shellcheck source=/dev/null
        source "$SETUP_SCRIPT"
    fi
}
