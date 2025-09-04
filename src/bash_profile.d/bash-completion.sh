#!/usr/bin/env bash

if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
    if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
        BASH_COMPLETION_SCRIPT="$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
    fi
fi

if [[ -n ${BASH_COMPLETION_SCRIPT:-} ]]; then
    # shellcheck source=/dev/null
    source "$BASH_COMPLETION_SCRIPT"
else
    echo "Warning: bash-completion not found. Install with 'brew install bash-completion@2'" >&2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
for i in "$SCRIPT_DIR"/src/completions/*; do
    # shellcheck source=/dev/null
    source "$i"
done
