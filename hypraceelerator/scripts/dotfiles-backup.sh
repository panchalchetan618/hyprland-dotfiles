#!/bin/bash
set -euo pipefail

BACKUP_ROOT="$HOME/Backups/dotfiles"
STAMP=$(date +%Y-%m-%d)
DEST="$BACKUP_ROOT/$STAMP"

mkdir -p "$DEST"

if [[ -d "$HOME/dotfiles" ]]; then
    rsync -a --delete "$HOME/dotfiles/" "$DEST/dotfiles/"
fi

if [[ -d "$HOME/.config" ]]; then
    rsync -a --delete "$HOME/.config/" "$DEST/config/"
fi

# Keep last 4 backups (about a month)
cd "$BACKUP_ROOT" || exit 0
ls -1d */ 2>/dev/null | sort -r | tail -n +5 | xargs -r rm -rf
