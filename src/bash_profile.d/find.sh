#!/usr/bin/env bash

function find {
    {
        local SET_X=0
        if shopt -po xtrace 1> /dev/null; then
            SET_X=1
            set +x
        fi
    } 2> /dev/null

    local -a ARGS
    for i in "$@"; do
        if [[ $i =~ -i?regex ]]; then
            ARGS+=(-regextype posix-extended)
        fi

        ARGS+=("$i")
    done

    command find "${ARGS[@]}"
    local RV=$?

    if [[ $SET_X -eq 1 ]]; then
        set -x
    fi

    {
        return $RV
    } 2> /dev/null
}

export -f find
