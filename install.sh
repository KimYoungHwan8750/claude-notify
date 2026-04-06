#!/bin/bash
set -e

EDITOR="vscode"
INSTALL_DIR="$HOME/.claude/claude-code-toast"

usage() {
    echo "Usage: install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --editor <name>   Set default editor (default: vscode)"
    echo "                    Supported: vscode, cursor, windsurf"
    echo "  --help            Show this help"
    echo ""
    echo "Examples:"
    echo "  bash install.sh"
    echo "  bash install.sh --editor cursor"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --editor)
            EDITOR="$2"
            shift 2
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
echo "  Install dir: $INSTALL_DIR"

# Copy files
mkdir -p "$INSTALL_DIR"
cp notify-hook.sh "$INSTALL_DIR/"
cp notify-hook.ps1 "$INSTALL_DIR/"

# Write config
cat > "$INSTALL_DIR/config.json" <<EOF
{
  "editor": "$EDITOR"
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

echo ""
echo "Done! Restart Claude Code to activate notifications."
echo ""
echo "To change editor later, edit: $INSTALL_DIR/config.json"
