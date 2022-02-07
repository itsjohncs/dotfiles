## color_mode: Changes terminal color profile.
# shellcheck disable=SC2120
function color_mode {
    local MODE
    MODE="${1-"$(defaults read -g AppleInterfaceStyle 2>/dev/null)"}"
    if [[ -z $MODE ]]; then
        MODE=Light
    fi

    if [[ $MODE == Light || $MODE == Dark ]]; then
        osascript -e "tell application \"Terminal\"
          set current settings of tabs of windows to settings set \"Solarized $MODE\"
        end tell" &
    else
        echo "USAGE: color_mode [MODE]"
        echo
        echo "Updates terminal color profile to match current OS color"
        echo "Light/Dark setting. MODE may be specified explicitly as 'Light'"
        echo "or 'Dark'."
        return 1
    fi
}

color_mode
