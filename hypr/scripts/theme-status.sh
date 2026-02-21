#!/bin/bash
set -euo pipefail

STATE_FILE="$HOME/.cache/hypraceelerator/state.env"

if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
fi

MODE="${MODE:-dark}"

if [[ "$MODE" == "light" ]]; then
    echo true
else
    echo false
fi
