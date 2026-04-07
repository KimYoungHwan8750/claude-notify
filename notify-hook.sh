#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Unique tmpfile per invocation — multiple Claude sessions can fire hooks
# concurrently, and a shared file would be overwritten before the async
# PowerShell launched via wscript gets a chance to read it.
TMPFILE="$SCRIPT_DIR/hook-$$-$RANDOM.json"
cat > "$TMPFILE"
wscript.exe "$SCRIPT_DIR/notify-hook.vbs" "$TMPFILE"
