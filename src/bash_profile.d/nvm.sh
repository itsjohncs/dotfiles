export NVM_DIR="$HOME/.nvm"

# Running `nvm use 14.17.6` after sourcing nvm.sh would have the same
# effect but take an extra second or so to run.
export PATH="$NVM_DIR/versions/node/v14.17.6/bin:$PATH"

# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use

# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
