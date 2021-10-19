# shellcheck disable=SC2120
function update_dark_light_mode {
    local MODE
    MODE="${1-"$(defaults read -g AppleInterfaceStyle)"}"
    if [[ $MODE == Light || $MODE == Dark ]]; then
        osascript -e "tell application \"Terminal\"
          set current settings of tabs of windows to settings set \"Solarized $MODE\"
        end tell"
    fi
}

update_dark_light_mode
