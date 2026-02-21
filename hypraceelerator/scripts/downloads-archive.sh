#!/bin/bash
set -euo pipefail

WATCH_DIR="$HOME/Downloads"
ARCHIVE_DIR="$WATCH_DIR/Archive"
DAYS_OLD=30

mkdir -p "$ARCHIVE_DIR"

find "$WATCH_DIR" -maxdepth 2 -type f -mtime +$DAYS_OLD \
    ! -path "$ARCHIVE_DIR/*" \
    -print0 | while IFS= read -r -d '' f; do
        mv -n "$f" "$ARCHIVE_DIR/"
    done
