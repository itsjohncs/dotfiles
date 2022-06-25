if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
else
    echo "WARNING: Could not find brew" >&2
fi

if [[ -d $HOMEBREW_PREFIX/opt/findutils/libexec/gnubin ]]; then
    export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
fi

if [[ -d $HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin ]]; then
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
fi
