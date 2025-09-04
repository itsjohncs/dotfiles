#!/usr/bin/env bash

## qc: ask an LLM for a command and drop into a shell to edit it, then run it directly

# This is some somewhat gnarly code that works around a history-problem... When
# we add the command `qc` generates to the history during `qc`'s execution, that
# prevents `bash` from adding the actual `qc` command to the history. So we need
# to do that manually. But to get the exact invocation of `qc` we need to add a
# DEBUG trap and use `BASH_COMMAND`... which is what all this wiring is for.

__qc_at_prompt=0
__qc_set_prompt_flag() { __qc_at_prompt=1; }
__qc_install_prompt_flag() {
    # Array form (newer Bash 4.4+)
    # shellcheck disable=SC2178,SC2128
    if declare -p PROMPT_COMMAND 2>/dev/null | grep -q 'declare \-a PROMPT_COMMAND='; then
        local e
        for e in "${PROMPT_COMMAND[@]}"; do
            [[ $e == __qc_set_prompt_flag ]] && return
        done
        PROMPT_COMMAND+=(__qc_set_prompt_flag)
        return
    else
        # String form (macOS / older Bash)
        local pc="${PROMPT_COMMAND}"

        # Strip trailing semicolons and whitespace
        pc="$(printf '%s' "$pc" | sed -e 's/[[:space:];]*$//')"

        case "$pc" in
        *"__qc_set_prompt_flag") ;; # already there, nothing to do
        '') PROMPT_COMMAND="__qc_set_prompt_flag" ;;
        *) PROMPT_COMMAND="$pc; __qc_set_prompt_flag" ;;
        esac
    fi
}
__qc_install_prompt_flag

__qc_last_invocation=
__qc_debug_capture() {
    if [[ $__qc_at_prompt == 1 ]]; then
        __qc_at_prompt=0
        __qc_last_invocation=$BASH_COMMAND
    fi
}
trap '__qc_debug_capture' DEBUG

qc() {
    if [[ $# -eq 0 || $1 == --help || $1 == -h ]]; then
        echo "Usage: qc <natural-language request>" >&2
        return 2
    fi

    # Check if llm is installed
    if ! command -v llm >/dev/null 2>&1; then
        echo "qc: 'llm' command not found" >&2
        echo "Install with: uv tool install llm" >&2
        echo "Then install the extension: llm install llm-cmd-comp" >&2
        return 1
    fi

    local cmd
    if ! cmd="$(llm cmdcomp "$*")"; then
        return 1
    fi

    if [[ -z $cmd ]]; then
        echo "qc: no command returned" >&2
        return 1
    fi

    # Adds command to history. Since this messes up the addition of the
    # original `qc` command to the history, do that explicitly.
    if [[ $__qc_last_invocation == qc\ * ]]; then
        history -s "$__qc_last_invocation"
    else
        echo "qc: couldn't retrieve qc invocation to put into history"
    fi
    history -s "$cmd"

    eval "$cmd"
}
