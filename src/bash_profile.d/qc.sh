#!/usr/bin/env bash

## qc: ask an LLM for a command and drop into a shell to edit it, then run it directly

qc() {
    if [[ $# -eq 0 || $1 == --help || $1 == -h ]]; then
        echo "Usage: qc <natural-language request>" >&2
        return 2
    fi

    local cmd
    if ! cmd="$(llm cmdcomp "$*")"; then
        return 1
    fi

    if [[ -z $cmd ]]; then
        echo "qc: no command returned" >&2
        return 1
    fi

    # Adds command to history
    history -s "$cmd"

    eval "$cmd"
}
