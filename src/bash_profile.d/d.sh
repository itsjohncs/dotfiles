## d: Alias for cd (with a little extra functionality)
function d {
    if [[ $# -eq 1 && -f $1 && ! -d $1 ]]; then
        local DIRNAME
        DIRNAME="$(dirname "$1")"
        if [[ ! $PWD -ef $DIRNAME ]]; then
            echo "correcting: $1 -> $DIRNAME"
            cd "$DIRNAME" || return $?
        fi
    fi

    cd "$@" || return $?
}
