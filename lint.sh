#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1 ; pwd -P )"

# Get short relative path so output is nicer
ROOT_DIR="$(realpath --relative-to="$PWD" "$SCRIPT_DIR")"

function bash_shebang_present {
    [[ $(head -n 1 "$1" | tr -d "\n") == "#!/usr/bin/env bash" ]]
}
export -f bash_shebang_present

find "$ROOT_DIR" \
    -name ".?*" -prune -o \
    \( -name "*.sh" -o \
       -name "bash_profile.dotfiles" -o \
       -type f -a -exec bash -c 'bash_shebang_present "$0"' {} \; \) \
    -print0 \
    | xargs -0t shellcheck --shell bash
