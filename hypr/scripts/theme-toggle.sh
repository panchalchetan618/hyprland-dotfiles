#!/bin/bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/hypraceelerator"
STATE_FILE="$CACHE_DIR/state.env"

if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
fi

WALLPAPER="${WALLPAPER:-}"
MODE="${MODE:-dark}"

if [[ -z "$WALLPAPER" ]]; then
    notify-send "Theme" "No wallpaper state found" -u critical
    exit 1
fi

if [[ "$MODE" == "dark" ]]; then
    NEW_MODE="light"
else
    NEW_MODE="dark"
fi

"$HOME/.config/hypr/scripts/theme-apply.sh" "$WALLPAPER" "$NEW_MODE"
