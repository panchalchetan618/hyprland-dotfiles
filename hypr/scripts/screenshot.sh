#!/bin/bash
# Feature-rich screenshot script for Hyprland
# Saves to file, copies to clipboard, optional annotation

SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"

show_help() {
    echo "Usage: screenshot.sh [mode] [options]"
    echo "Modes: region, window, monitor, full"
    echo "Options: --edit (open in swappy for annotation)"
}

take_screenshot() {
    local mode="$1"
    local edit="$2"
    local filename="$(date +%Y-%m-%d_%H-%M-%S).png"
    local filepath="$SCREENSHOTS_DIR/$filename"
    local tmp_file="/tmp/screenshot_$$.png"

    case "$mode" in
        region)
            hyprcap shot region -w -c -n -o "$SCREENSHOTS_DIR" -f "$filename" --freeze
            ;;
        window)
            hyprcap shot window -w -c -n -o "$SCREENSHOTS_DIR" -f "$filename"
            ;;
        monitor|full)
            hyprcap shot monitor:active -w -c -n -o "$SCREENSHOTS_DIR" -f "$filename"
            ;;
        *)
            # Interactive selection via fuzzel/rofi
            hyprcap shot -w -c -n -o "$SCREENSHOTS_DIR" -f "$filename"
            ;;
    esac

    # Open in swappy for annotation if --edit flag
    if [[ "$edit" == "--edit" ]] && [[ -f "$filepath" ]]; then
        swappy -f "$filepath" -o "$filepath"
        # Re-copy edited version to clipboard
        wl-copy < "$filepath"
        notify-send "Screenshot edited" "Saved and copied to clipboard"
    fi
}

# Parse arguments
MODE="${1:-region}"
EDIT=""

for arg in "$@"; do
    case "$arg" in
        --edit|-e)
            EDIT="--edit"
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac
done

take_screenshot "$MODE" "$EDIT"
