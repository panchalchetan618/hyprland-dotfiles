#!/bin/bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/hypraceelerator"
mkdir -p "$CACHE_DIR"

# Low disk alert
DISK_THRESHOLD=90
DISK_STATE="$CACHE_DIR/low-disk.state"
root_use=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')
if [[ "$root_use" -ge "$DISK_THRESHOLD" ]]; then
    if [[ ! -f "$DISK_STATE" || $(date -r "$DISK_STATE" +%s) -lt $(date -d 'today 00:00' +%s) ]]; then
        notify-send "System" "Low disk space: ${root_use}% used" -u critical || true
        touch "$DISK_STATE"
    fi
fi

# Low battery alert
BAT_DIR=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)
if [[ -n "$BAT_DIR" ]]; then
    cap=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo 100)
    status=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")
    if [[ "$cap" -le 15 && "$status" != "Charging" ]]; then
        notify-send "Battery" "Battery low: ${cap}%" -u critical || true
    elif [[ "$cap" -le 25 && "$status" != "Charging" ]]; then
        notify-send "Battery" "Battery: ${cap}%" -u normal || true
    fi
fi
