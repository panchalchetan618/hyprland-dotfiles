#!/bin/bash
set -euo pipefail

MAX_ITEMS=200

if ! command -v cliphist >/dev/null 2>&1; then
    exit 0
fi

mapfile -t entries < <(cliphist list | tail -n +$((MAX_ITEMS + 1)) | awk '{print $1}')
if [[ ${#entries[@]} -eq 0 ]]; then
    exit 0
fi

for id in "${entries[@]}"; do
    cliphist delete "$id" >/dev/null 2>&1 || true

done
