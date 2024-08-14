function __main {
    alias s="ls"

    alias ga="git add"
    alias gc="git checkout"
    alias gb="git branch"
    alias gd="git diff"
    alias gdc="git diff --cached"
    alias gg="rg"
    alias gcp="git cherry-pick"
    alias gl="git log"
    alias gm="git commit"
    alias gms="git commit -m 'nopush: squash me'"
    alias gr="git reset"
    alias gs="git status"
    alias gsh="git show"
    alias gff="git merge --ff-only"
    alias mk="cowsay 'Hi! I love you 💞' && clear"
    alias pre="open -a Preview.app"
    alias t="TIMCOL_NAME=t timcol"

    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

    # Aliases are used instead of symbolic links because cygwin doesn't support
    # them. The shellcheck disable directives are because of a warning about
    # $SCRIPT_DIR's early expansion.

    # shellcheck disable=SC2139
    alias git="$(realpath "$SCRIPT_DIR/../git-select/src/forward.py")"

    # shellcheck disable=SC2139
    alias gn="$(realpath "$SCRIPT_DIR/../git-select/src/copy.py")"
}

__main
