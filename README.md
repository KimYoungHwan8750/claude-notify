# claude-code-toast

English | [한국어](README.ko.md)

Windows toast notifications for Claude Code. Know when your task is done without watching the terminal.

![Windows 11](https://img.shields.io/badge/Windows%2011-0078D4?logo=windows11&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-Hook-orange)

## What it does

- Shows a Windows toast notification when Claude Code finishes a response or needs input
- Displays the **project name** and a **summary** of what Claude said
- Click the notification to **focus your editor** on that project

## Supported Editors

| Editor | Protocol | Status |
|--------|----------|--------|
| VS Code | `vscode://` | Default |
| Cursor | `cursor://` | `--editor cursor` |
| Windsurf | `windsurf://` | `--editor windsurf` |

Any editor that supports `<name>://file/<path>` protocol works — just pass the name.

## Install

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-toast.git
cd claude-code-toast
bash install.sh
```

With Cursor as default editor:
```bash
bash install.sh --editor cursor
```

With custom waiting message (e.g. Korean):
```bash
bash install.sh --editor cursor --waiting-text "입력 대기 중"
```

## Manual Setup

1. Copy `notify-hook.sh` and `notify-hook.ps1` to `~/.claude/claude-code-toast/`
2. Create `config.json`:
   ```json
   {
     "editor": "vscode",
     "waitingText": "Waiting for input"
   }
   ```
3. Add hooks to `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/claude-code-toast/notify-hook.sh", "timeout": 8}]}],
       "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/claude-code-toast/notify-hook.sh", "timeout": 8}]}]
     }
   }
   ```

## How it works

```
Claude Code (Stop/Notification event)
  → stdin JSON piped to notify-hook.sh
  → saves JSON to temp file (stdin can't pass through `start`)
  → `start` launches PowerShell in desktop session
  → notify-hook.ps1 reads JSON, builds toast XML
  → Windows Toast API shows notification
  → click → editor focuses via protocol URI
```

## Troubleshooting

### Notifications not showing
- **Do Not Disturb / Focus Assist** must be OFF (most common issue)
- Check Windows Settings > System > Notifications is enabled

### Toast shows but disappears instantly
- This is controlled by Windows notification settings
- Settings > System > Notifications > adjust display duration

### Click doesn't focus editor
- Make sure your editor is registered as a protocol handler (installed normally via installer, not portable)

## Change editor

## Configuration

Edit `~/.claude/claude-code-toast/config.json`:

```json
{
  "editor": "cursor",
  "waitingText": "Waiting for input"
}
```

| Key | Description | Default |
|-----|-------------|---------|
| `editor` | Editor protocol name for click-to-focus | `vscode` |
| `waitingText` | Body text shown on `Notification` event | `Waiting for input` |

No restart needed — takes effect on next notification.

## Requirements

- Windows 10/11
- Claude Code with hooks support
- Git Bash (comes with Git for Windows)

## License

MIT
