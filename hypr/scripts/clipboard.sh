#!/bin/bash
# Clipboard history manager using cliphist and rofi

case "$1" in
    pick|"")
        # Show clipboard history and paste selection
        cliphist list | rofi -dmenu -p "  Clipboard" -i -display-columns 2 -theme-str 'window {width: 600px;} listview {lines: 12;}' | cliphist decode | wl-copy
        ;;
    delete)
        # Select and delete an entry
        cliphist list | rofi -dmenu -p "Delete Entry" -i -display-columns 2 | cliphist delete
        ;;
    clear)
        # Clear all clipboard history
        cliphist wipe
        notify-send "Clipboard Cleared" "All history has been deleted"
        ;;
    *)
        echo "Usage: clipboard.sh [pick|delete|clear]"
        ;;
esac
