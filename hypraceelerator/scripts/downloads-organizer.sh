#!/bin/bash
set -euo pipefail

WATCH_DIR="$HOME/Downloads"
LOG_DIR="$HOME/.cache/hypraceelerator"
LOG_FILE="$LOG_DIR/downloads-organizer.log"

mkdir -p "$LOG_DIR"

move_file() {
    local file="$1"
    local base
    base=$(basename "$file")
    local ext="${base##*.}"

    shopt -s nocasematch
    case "$ext" in
        jpg|jpeg|png|gif|webp|svg|heic) dest="$WATCH_DIR/Images" ;;
        mp4|mkv|mov|avi|webm) dest="$WATCH_DIR/Videos" ;;
        mp3|wav|flac|m4a|ogg) dest="$WATCH_DIR/Audio" ;;
        pdf|doc|docx|xls|xlsx|ppt|pptx|txt|md|rtf|csv) dest="$WATCH_DIR/Documents" ;;
        zip|rar|7z|tar|gz|bz2|xz) dest="$WATCH_DIR/Archives" ;;
        iso|dmg|appimage|pkg|deb|rpm) dest="$WATCH_DIR/Installers" ;;
        torrent) dest="$WATCH_DIR/Torrents" ;;
        *) dest="$WATCH_DIR/Other" ;;
    esac
    shopt -u nocasematch

    mkdir -p "$dest"
    if [[ -f "$file" ]]; then
        mv -n "$file" "$dest/" && echo "$(date -Iseconds) moved $base -> $dest" >> "$LOG_FILE"
    fi
}

initial_sort() {
    find "$WATCH_DIR" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' f; do
        move_file "$f"
    done
}

if command -v inotifywait >/dev/null 2>&1; then
    initial_sort
    inotifywait -m -e close_write,create,moved_to --format '%w%f' "$WATCH_DIR" | while read -r f; do
        move_file "$f"
    done
else
    initial_sort
    exit 0
fi
