#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1 ; pwd -P )"

swiftc "$SCRIPT_DIR/src/dark-mode-notify/dark-mode-notify.swift" \
       -o "$HOMEBREW_PREFIX/bin/dark-mode-notify"

mkdir -p "$HOMEBREW_PREFIX/var/log/dark-mode-notify"

cat > "$HOME/Library/LaunchAgents/ke.bou.dark-mode-notify.plist" << EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ke.bou.dark-mode-notify</string>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>$HOMEBREW_PREFIX/var/log/dark-mode-notify/stderr.log</string>
    <key>StandardOutPath</key>
    <string>$HOMEBREW_PREFIX/var/log/dark-mode-notify/stdout.log</string>
    <key>ProgramArguments</key>
    <array>
       <string>$HOMEBREW_PREFIX/bin/dark-mode-notify</string>
       <string>$SCRIPT_DIR/src/bash_profile.d/0color-mode.sh</string>
    </array>
</dict>
</plist>
EOM

launchctl unload "$HOME/Library/LaunchAgents/ke.bou.dark-mode-notify.plist"
launchctl load -w "$HOME/Library/LaunchAgents/ke.bou.dark-mode-notify.plist"
