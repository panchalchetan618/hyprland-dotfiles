#!/bin/bash
# Wallpaper initialization script
# Handles first-run and selects a wallpaper automatically

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CACHE_FILE="$HOME/.cache/wallpaper-theme/last-wallpaper"

# Ensure directories exist
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$(dirname "$CACHE_FILE")"

# Function to find a wallpaper
find_wallpaper() {
    # First, try the last used wallpaper
    if [[ -f "$CACHE_FILE" ]]; then
        local last=$(cat "$CACHE_FILE")
        if [[ -f "$last" ]]; then
            echo "$last"
            return
        fi
    fi

    # Find any wallpaper in the directory
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | head -1
}

# Main
WALLPAPER=$(find_wallpaper)

if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    # Save for next time
    echo "$WALLPAPER" > "$CACHE_FILE"
    # Apply wallpaper with theme
    "$SCRIPT_DIR/wallpaper-theme.sh" "$WALLPAPER"
else
    # No wallpapers found - just set a solid color
    swww clear 1e1e2e 2>/dev/null || true
    notify-send "Wallpaper Setup" "Add images to ~/Pictures/Wallpapers/\nThen press Super+W to select one" -u normal
fi
