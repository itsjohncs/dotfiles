#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1 ; pwd -P )"

# Get short relative path so output is nicer
ROOT_DIR="$(realpath --relative-to="$PWD" "$SCRIPT_DIR")"

function shebang_present {
    [[ $(head -n 1 "$2" | tr -d "\n") == "$1" ]]
}
export -f shebang_present

find "$ROOT_DIR" \
    \( -name ".?*" -o -path "./src/complete-alias" \) -prune -o \
    \( -name "*.sh" -o \
       -path "./bash_profile.dotfiles" -o \
       -type f -a -exec bash \
           -c 'shebang_present "#!/usr/bin/env bash" "$0"' {} \; \) \
    -print0 \
    | xargs -0t shellcheck --shell bash

find "$ROOT_DIR" \
    \( -name ".?*" -o -path "./src/complete-alias" \) -prune -o \
    -type f -a -exec bash \
        -c 'shebang_present "#!/usr/bin/env python3" "$0"' {} \; \
    -print0 \
    | xargs -0t pylint --disable=C0103,C0114,C0116

find "$ROOT_DIR" \
    \( -name ".?*" -o -path "./src/complete-alias" \) -prune -o \
    -type f -a -exec bash \
        -c 'shebang_present "#!/usr/bin/env node" "$0"' {} \; \
    -print0 \
    | xargs -0t npx eslint
