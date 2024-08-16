function which {
    if [[ $# -eq 0 ]]; then
        command which
    elif [[ ${*: -1} == -* ]]; then
        command which "$@"
    else
        local CMD_OUTPUT
        CMD_OUTPUT=$(command -v "${@: -1}")
        if [[ $CMD_OUTPUT == alias* ]]; then
            command which "${@:1:$#-1}" "$CMD_OUTPUT"
        else
            command which "$@"
        fi
    fi
}
