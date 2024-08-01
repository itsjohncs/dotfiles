#!/usr/bin/env bash

function __supports_local_dash {
    local - 2>/dev/null
}

if __supports_local_dash; then
    function find {
        {
            local -
            set +xe
        } 2>/dev/null

        local -a ARGS
        for i in "$@"; do
            if [[ $i =~ -i?regex ]]; then
                ARGS+=(-regextype posix-extended)
            elif [[ $i == -regextype ]]; then
                ARGS=("$@")
                break
            fi

            ARGS+=("$i")
        done

        command find "${ARGS[@]}"
    }

    export -f find
else
    echo "WARNING: Version of bash is too old for find shim. Upgrade to >=4.4." 2>/dev/null
fi
