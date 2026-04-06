#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPFILE="$SCRIPT_DIR/hook-last.json"
cat > "$TMPFILE"
wscript.exe "$SCRIPT_DIR/notify-hook.vbs" "$TMPFILE"
