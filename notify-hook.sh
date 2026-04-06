#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPFILE="$SCRIPT_DIR/hook-last.json"
cat > "$TMPFILE"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/notify-hook.ps1" "$TMPFILE"
