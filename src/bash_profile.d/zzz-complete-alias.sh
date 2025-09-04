#!/usr/bin/env bash

# Set up complete-alias for all aliases
# This needs to run last (after we set up the aliases), hence the zzz prefix

if [[ -n ${BASH_COMPLETION_SCRIPT:-} ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/src/complete-alias/complete_alias"

    # Override the alias body function to provide proper completion for git
    __compal__get_alias_body() {
        local cmd="$1"
        if [[ $cmd == "git" ]]; then
            echo "git"
        else
            local body
            body="$(alias "$cmd")"
            echo "${body#*=}" | command xargs
        fi
    }

    mapfile -t ALIASES < <(
        printf "%s\n" "${!BASH_ALIASES[@]}"
    )

    if [[ ${#ALIASES[@]} -gt 0 ]]; then
        complete -F _complete_alias "${ALIASES[@]}"
    fi
fi
