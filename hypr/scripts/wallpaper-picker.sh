#!/bin/bash
# Wallpaper Picker - macOS style
# Beautiful rofi-based wallpaper selector with preview

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
THEME="$HOME/.config/rofi/popup.rasi"

mkdir -p "$CACHE_DIR"

# Get all wallpapers
get_wallpapers() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | sort
}

# Generate thumbnail for rofi icon
generate_thumb() {
    local img="$1"
    local name=$(basename "$img" | sed 's/\.[^.]*$//')
    local thumb="$CACHE_DIR/${name}.png"

    if [[ ! -f "$thumb" ]] || [[ "$img" -nt "$thumb" ]]; then
        convert "$img" -resize 64x64^ -gravity center -extent 64x64 "$thumb" 2>/dev/null
    fi

    echo "$thumb"
}

# Build menu entries
build_menu() {
    while read -r img; do
        local name=$(basename "$img")
        local thumb=$(generate_thumb "$img")
        echo -e "$name\x00icon\x1f$thumb"
    done <<< "$(get_wallpapers)"
}

# Show picker
show_picker() {
    local selected=$(build_menu | rofi -dmenu \
        -p "󰸉  Wallpaper" \
        -show-icons \
        -theme "$THEME" \
        -theme-str 'window { width: 400px; location: center; }' \
        -theme-str 'listview { lines: 8; }' \
        -theme-str 'element-icon { size: 48px; }')

    if [[ -n "$selected" ]]; then
        local wallpaper="$WALLPAPER_DIR/$selected"
        if [[ -f "$wallpaper" ]]; then
            "$SCRIPT_DIR/wallpaper-theme.sh" "$wallpaper"
        fi
    fi
}

# Random wallpaper
set_random() {
    local wallpaper=$(get_wallpapers | shuf -n1)
    if [[ -f "$wallpaper" ]]; then
        "$SCRIPT_DIR/wallpaper-theme.sh" "$wallpaper"
    fi
}

# Main
case "$1" in
    random) set_random ;;
    *) show_picker ;;
esac
