#!/bin/bash
set -euo pipefail

BAT_DIR=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)
if [[ -z "$BAT_DIR" ]]; then
    echo '{"text":"--","class":"b0"}'
    exit 0
fi

CAPACITY=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo 0)
STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")

if [[ "$CAPACITY" =~ ^[0-9]+$ ]]; then
    :
else
    CAPACITY=0
fi

LEVEL=$(( (CAPACITY + 9) / 10 ))
if [[ $LEVEL -lt 0 ]]; then LEVEL=0; fi
if [[ $LEVEL -gt 10 ]]; then LEVEL=10; fi

CLASS="b${LEVEL}"
if [[ "$STATUS" == "Charging" ]]; then
    CLASS="$CLASS charging"
elif [[ "$STATUS" == "Full" ]]; then
    CLASS="b10"
fi

printf '{"text":"%s%%","class":"%s"}\n' "$CAPACITY" "$CLASS"
