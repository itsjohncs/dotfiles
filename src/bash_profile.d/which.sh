function which {
    if [[ $# -eq 0 ]]; then
        command which
    elif [[ ${*: -1} == -* ]]; then
        command which "$@"
    else
        command which "${@:1:$#-1}" "$(command -v "${@: -1}")"
    fi
}
