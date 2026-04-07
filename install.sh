#!/bin/bash
set -e

EDITOR="vscode"
LANG_CODE="en"
HIDE_TITLE=1
INSTALL_DIR="$HOME/.claude/claude-code-toast"

usage() {
    echo "Usage: install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --editor <name>     Set default editor (default: vscode)"
    echo "                      Supported: vscode, cursor, windsurf"
    echo "  --lang <code>       Notification language (default: en)"
    echo "                      Supported: en, ko"
    echo "  --no-hide-profile   Skip patching editor's window.title setting"
    echo "                      (by default, the installer hides file name and"
    echo "                      profile name from the editor's window title)"
    echo "  --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  bash install.sh"
    echo "  bash install.sh --editor cursor"
    echo "  bash install.sh --editor cursor --lang ko"
    echo "  bash install.sh --editor cursor --no-hide-profile"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --editor)
            EDITOR="$2"
            shift 2
            ;;
        --lang)
            LANG_CODE="$2"
            shift 2
            ;;
        --no-hide-profile)
            HIDE_TITLE=0
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo "Installing claude-code-toast..."
echo "  Editor: $EDITOR"
echo "  Language: $LANG_CODE"
echo "  Install dir: $INSTALL_DIR"

# Copy files
mkdir -p "$INSTALL_DIR"
cp notify-hook.sh "$INSTALL_DIR/"
cp notify-hook.ps1 "$INSTALL_DIR/"
cp notify-hook.vbs "$INSTALL_DIR/"
cp translations.json "$INSTALL_DIR/"

# Write config
cat > "$INSTALL_DIR/config.json" <<EOF
{
  "editor": "$EDITOR",
  "lang": "$LANG_CODE"
}
EOF

# Update Claude Code settings
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_CMD="bash $INSTALL_DIR/notify-hook.sh"

if [ ! -f "$SETTINGS_FILE" ]; then
    cat > "$SETTINGS_FILE" <<EOF
{
  "hooks": {
    "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOOK_CMD", "timeout": 8}]}],
    "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOOK_CMD", "timeout": 8}]}]
  }
}
EOF
    echo "Created $SETTINGS_FILE with hooks."
else
    # Check if hooks already configured
    if grep -q "claude-code-toast" "$SETTINGS_FILE" 2>/dev/null; then
        echo "Hooks already configured in $SETTINGS_FILE"
    else
        echo ""
        echo "Add the following to your $SETTINGS_FILE:"
        echo ""
        echo '  "hooks": {'
        echo '    "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "'"$HOOK_CMD"'", "timeout": 8}]}],'
        echo '    "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "'"$HOOK_CMD"'", "timeout": 8}]}]'
        echo '  }'
        echo ""
    fi
fi

if [ "$HIDE_TITLE" = "1" ]; then
    case "$EDITOR" in
        vscode)   EDITOR_DIR="Code" ;;
        cursor)   EDITOR_DIR="Cursor" ;;
        windsurf) EDITOR_DIR="Windsurf" ;;
        *)        EDITOR_DIR="" ;;
    esac

    if [ -z "$EDITOR_DIR" ] || [ -z "$APPDATA" ]; then
        echo ""
        echo "[skip] Cannot patch window.title (unsupported editor or APPDATA missing)"
    else
        SETTINGS="$APPDATA/$EDITOR_DIR/User/settings.json"
        TITLE_VALUE='${activeEditorShort} [${rootName}]'
        echo ""
        echo "Patching $EDITOR_DIR window.title (hides profile name and editor name)..."

        if [ ! -f "$SETTINGS" ] || [ ! -s "$SETTINGS" ]; then
            mkdir -p "$(dirname "$SETTINGS")"
            printf '{\n  "window.title": "%s"\n}\n' "$TITLE_VALUE" > "$SETTINGS"
            echo "  Created $SETTINGS"
        elif grep -q '"window\.title"' "$SETTINGS"; then
            echo "  window.title already set, leaving alone"
        elif grep -qzE '^\s*\{\s*\}\s*$' "$SETTINGS"; then
            printf '{\n  "window.title": "%s"\n}\n' "$TITLE_VALUE" > "$SETTINGS"
            echo "  Replaced empty object in $SETTINGS"
        else
            if grep -qzE ',\s*\}\s*$' "$SETTINGS"; then SEP=""; else SEP=","; fi
            sed -i ":a;\$!{N;ba}; s|\\(.*\\)}|\\1${SEP} \"window.title\": \"${TITLE_VALUE}\"\\n}|" "$SETTINGS"
            echo "  Inserted into $SETTINGS"
        fi

        echo "  (restart $EDITOR_DIR to take effect)"
    fi
fi

echo ""
echo "Done! Restart Claude Code to activate notifications."
echo ""
echo "To change editor or language later, edit: $INSTALL_DIR/config.json"
