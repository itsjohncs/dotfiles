if [[ -d /usr/local/opt/findutils/libexec/gnubin ]]; then
    export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
fi

if [[ -d /usr/local/opt/coreutils/libexec/gnubin ]]; then
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi
