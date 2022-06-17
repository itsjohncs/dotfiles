function __main {
    alias s="ls"

    alias ga="git add"
    alias gc="git checkout"
    alias gb="git branch"
    alias gd="git diff"
    alias gdc="git diff --cached"
    alias gg="git grep --untracked --line-number"
    alias gl="git log"
    alias gm="git commit"
    alias gr="git reset"
    alias gs="git status"
    alias gsh="git show"
    alias mk="cowsay 'Hi! I love you 💞' && clear"
    alias pre="open -a Preview.app"

    local SCRIPT_DIR
    SCRIPT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P )"

    # shellcheck disable=SC2139 # would warn about SCRIPT_DIR's early expansion
    alias git="$(realpath "$SCRIPT_DIR/../git-select/src/forward.py")"
}

__main
