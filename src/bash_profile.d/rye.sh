if [[ ! -d $HOME/.rye ]]; then
    echo "WARNING: rye not installed"
    return
fi

# shellcheck source=/dev/null
source ~/.rye/env
