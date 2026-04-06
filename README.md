# claude-code-toast

English | [한국어](README.ko.md)

Windows toast notifications for Claude Code. Know when your task is done without watching the terminal.

![Windows 10/11](https://img.shields.io/badge/Windows%2010%2F11-0078D4?logo=windows&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-Hook-orange)

## What it does

- Shows a Windows toast notification when Claude Code finishes a response or needs input
- Displays the **project name** and a **summary** of what Claude said
- **Smart click behavior**:
  - If the project is already open in your editor → click focuses that window
  - If the project isn't open (terminal-only work) → click is a no-op, so you don't get an unwanted new window
- Notification **persists** until you dismiss it (no more missed alerts)
- **Multilingual** — English (default) and Korean built-in

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

With Korean language:
```bash
bash install.sh --editor cursor --lang ko
```

## Manual Setup

1. Copy `notify-hook.sh` and `notify-hook.ps1` to `~/.claude/claude-code-toast/`
2. Create `config.json`:
   ```json
   {
     "editor": "vscode",
     "lang": "en"
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
  → notify-hook.ps1 reads JSON
  → checks if editor has project open (via Get-Process window titles)
  → builds toast XML with launch URI (or no-op if project not open)
  → Windows Toast API shows persistent notification
  → click → editor focuses via protocol URI
```

### Smart click behavior

When you click the notification, the script checks whether the target editor
is already running with your project. It does this by enumerating editor
processes (`Code.exe`, `Cursor.exe`, etc.) and matching the project folder
name against each window's title segments (split by ` - `).

- **Project is open** → clicking launches `<editor>://file/<path>`, which
  focuses the existing window
- **Project is not open** → clicking uses a background activation with no
  handler, so it just dismisses the notification instead of opening a new
  editor window (useful when you're working in the terminal only)

## Troubleshooting

### Notifications not showing
- **Do Not Disturb / Focus Assist** must be OFF (most common issue)
- Check Windows Settings > System > Notifications is enabled

### Toast shows but disappears instantly
- This is controlled by Windows notification settings
- Settings > System > Notifications > adjust display duration

### Click doesn't focus editor
- Make sure your editor is registered as a protocol handler (installed normally via installer, not portable)

## Configuration

Edit `~/.claude/claude-code-toast/config.json`:

```json
{
  "editor": "cursor",
  "lang": "ko"
}
```

| Key | Description | Default |
|-----|-------------|---------|
| `editor` | Editor protocol name for click-to-focus | `vscode` |
| `lang` | Notification language (`en`, `ko`) | `en` |

### Supported languages

| Code | Language | `Notification` event text |
|------|----------|---------------------------|
| `en` | English | `Waiting for input` |
| `ko` | Korean | `입력 대기 중` |

No restart needed — takes effect on next notification.

## Requirements

- Windows 10 (version 1607+) or Windows 11
- Claude Code with hooks support
- Git Bash (comes with Git for Windows)

## License

MIT
