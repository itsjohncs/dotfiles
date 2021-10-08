# Lines of history in memory
export HISTSIZE=10000

# Lines of history on disk (will have to grep ~/.bash_history for full listing)
export HISTFILESIZE=2000000

# Append to history instead of overwrite
shopt -s histappend

# Ignore redundant commands
export HISTCONTROL=ignoredups

# Multiple commands on one line show up as a single line
shopt -s cmdhist

# Update the history file after each command. This'll ensure that when we start
# a new shell we have everything.
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
