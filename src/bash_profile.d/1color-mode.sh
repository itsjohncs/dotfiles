#!/usr/bin/env bash

# Check if we're on a non-mac system.
if ! command -v osascript > /dev/null; then
    return
fi

if ! command -v dark-mode > /dev/null; then
    echo "WARNING: Could not find dark-mode." >&2
    return 1
fi

## color_mode: Changes terminal color profile.
# shellcheck disable=SC2120
function color_mode {
    local MODE
    if [[ ${1-} == --from-env ]]; then
        if [[ ${DARKMODE-1} -eq 0 ]]; then
            MODE=Light
        else
            MODE=Dark
        fi
    elif [[ -n ${1-} ]]; then
        MODE="$1"
    else
        local STATUS
        STATUS="$(dark-mode status)"
        if [[ $STATUS == off ]]; then
            MODE=Light
        else
            MODE=Dark
        fi
    fi

    if [[ $MODE == Light || $MODE == Dark ]]; then
        (
            osascript -e "tell application \"Terminal\"
                try
                    repeat with i in windows
                        set current settings of tabs in i to settings set \"Solarized $MODE\"
                    end repeat
                end try
            end tell" &
        )
    else
        echo "USAGE: color_mode [MODE]"
        echo
        echo "Updates terminal color profile to match current OS color"
        echo "Light/Dark setting. MODE may be specified explicitly as 'Light'"
        echo "or 'Dark'."
        return 1
    fi
}

# If this file has been sourced (ie: not run as a script) the command line
# arguments weren't meant for us.
if (return 0 2>/dev/null); then
    color_mode
else
    color_mode "$@"
fi
