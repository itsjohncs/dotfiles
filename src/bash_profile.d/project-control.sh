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

    subl "$PROJECT_DIR"
    cd "$PROJECT_DIR" || return $?
}
