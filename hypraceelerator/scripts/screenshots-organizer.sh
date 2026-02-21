#!/bin/bash
set -euo pipefail

SRC="$HOME/Pictures/Screenshots"
DST="$HOME/Pictures/Screenshots/By-Date"

mkdir -p "$DST"

find "$SRC" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0 | while IFS= read -r -d '' f; do
    date_dir=$(date -r "$f" +%Y-%m)
    mkdir -p "$DST/$date_dir"
    mv -n "$f" "$DST/$date_dir/"
done
