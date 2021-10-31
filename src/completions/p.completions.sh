function _p_completions {
    # ls is used over find because it's much faster
    mapfile -t COMPREPLY < <(
        compgen \
            -W "$(ls "$HOME/personal")" \
            "${COMP_WORDS[1]}"
    )
}

complete -F _p_completions p
complete -F _p_completions pd
