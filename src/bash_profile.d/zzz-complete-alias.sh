#!/usr/bin/env bash

# Set up complete-alias for all aliases
# This needs to run last (after we set up the aliases), hence the zzz prefix

if [[ -n ${BASH_COMPLETION_SCRIPT:-} ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/src/complete-alias/complete_alias"

    mapfile -t ALIASES < <(
        printf "%s\n" "${!BASH_ALIASES[@]}" |
            grep --invert-match "^git$"
    )

    if [[ ${#ALIASES[@]} -gt 0 ]]; then
        complete -F _complete_alias "${ALIASES[@]}"
    fi
fi
