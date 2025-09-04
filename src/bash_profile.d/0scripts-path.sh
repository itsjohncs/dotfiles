#!/usr/bin/env bash

# Add dotfiles scripts to PATH
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
export PATH="$SCRIPT_DIR/src/scripts/:$PATH"
