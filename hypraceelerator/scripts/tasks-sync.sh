#!/bin/bash
set -euo pipefail

if ! command -v vdirsyncer >/dev/null 2>&1; then
    exit 0
fi

vdirsyncer sync >/dev/null 2>&1 || true
