function _p_completions {
    # ls is used over find because it's much faster
    local PROJECTS=""
    for ROOT in "$HOME/personal" "$HOME/elicit"; do
        if [[ -d $ROOT ]]; then
            PROJECTS+=" $(ls "$ROOT")"
        fi
    done
    mapfile -t COMPREPLY < <(
        compgen \
            -W "$PROJECTS" \
            "${COMP_WORDS[1]}"
    )
}

complete -F _p_completions p
complete -F _p_completions pd
complete -F _p_completions pi
