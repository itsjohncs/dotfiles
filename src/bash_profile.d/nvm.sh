if [[ ! -d $HOME/.nvm ]]; then
    echo "WARNING: nvm not installed"
    return
fi

export NVM_DIR="$HOME/.nvm"

# Running `nvm use 14.17.6` after sourcing nvm.sh would have the same
# effect but take an extra second or so to run.
export PATH="$NVM_DIR/versions/node/v14.17.6/bin:$PATH"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh" --no-use
fi

if [[ -s "$NVM_DIR/bash_completion" ]]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/bash_completion"
fi
