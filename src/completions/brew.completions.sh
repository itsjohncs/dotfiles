function __main {
    if [[ -z ${HOMEBREW_PREFIX:-} ]]; then
        return
    fi

    local ENABLED=(
        git-completion.bash
        brew
    )

    local SRC
    for i in "${ENABLED[@]}"; do
        SRC="$HOMEBREW_PREFIX/etc/bash_completion.d/$i"
        if [[ -e $SRC ]]; then
            # shellcheck source=/dev/null
            source "$SRC"
        else
            echo "WARNING: Could not find completions at $SRC"
        fi
    done
}

__main
