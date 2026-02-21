#!/bin/bash
set -euo pipefail

if ! command -v khal >/dev/null 2>&1; then
    notify-send "Tasks" "Install khal for calendar events" -u normal || true
    exit 1
fi

prompt="Event (e.g. 2026-02-21 10:00 11:00 Team Sync)"
input=$(rofi -dmenu -p "$prompt" -i)

if [[ -z "$input" ]]; then
    exit 0
fi

khal new $input || notify-send "Tasks" "Failed to create event" -u critical || true
