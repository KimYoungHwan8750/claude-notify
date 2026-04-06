param([string]$JsonFile)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"

# Defaults
$editor = "vscode"
$lang = "en"

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($config.editor) { $editor = $config.editor }
    if ($config.lang) { $lang = $config.lang }
}

# Load translations from external JSON (keeps non-ASCII out of .ps1)
$translationsPath = Join-Path $scriptDir "translations.json"
$translations = Get-Content $translationsPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $translations.$lang) { $lang = "en" }
$t = $translations.$lang

$json = Get-Content $JsonFile -Raw -Encoding UTF8 | ConvertFrom-Json

$project = Split-Path $json.cwd -Leaf
$cwd = $json.cwd -replace '\\', '/'

$msg = $json.last_assistant_message
if ($msg.Length -gt 80) {
    $msg = $msg.Substring(0, 80) + "..."
}

$event = $json.hook_event_name

$title = "Claude Code [$project]"
if ($event -eq "Stop") {
    $body = $msg
} else {
    $body = $t.waitingForInput
}

# Map editor name to Windows process name
$processMap = @{
    "vscode"   = "Code"
    "cursor"   = "Cursor"
    "windsurf" = "Windsurf"
}
$processName = if ($processMap.ContainsKey($editor)) { $processMap[$editor] } else { $editor }

# Check if editor has this project open.
# Electron apps (VS Code, Cursor) may have many windows but Get-Process only
# returns one MainWindowTitle (the active one). We need Win32 EnumWindows to
# enumerate ALL top-level windows and match their titles.
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;

public class ToastWinApi {
    [DllImport("user32.dll")]
    static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int GetWindowTextW(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")]
    static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")]
    static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public static List<string> GetTitlesForPids(HashSet<uint> pids) {
        var titles = new List<string>();
        EnumWindows((hWnd, lParam) => {
            if (!IsWindowVisible(hWnd)) return true;
            int len = GetWindowTextLength(hWnd);
            if (len == 0) return true;
            uint pid;
            GetWindowThreadProcessId(hWnd, out pid);
            if (!pids.Contains(pid)) return true;
            var sb = new StringBuilder(len + 1);
            GetWindowTextW(hWnd, sb, sb.Capacity);
            titles.Add(sb.ToString());
            return true;
        }, IntPtr.Zero);
        return titles;
    }
}
"@ -ErrorAction SilentlyContinue

$pids = New-Object 'System.Collections.Generic.HashSet[uint32]'
Get-Process -Name $processName -ErrorAction SilentlyContinue | ForEach-Object {
    [void]$pids.Add([uint32]$_.Id)
}

$isProjectOpen = $false
if ($pids.Count -gt 0) {
    $titles = [ToastWinApi]::GetTitlesForPids($pids)
    foreach ($title in $titles) {
        $segments = $title -split ' - '
        if ($segments -contains $project) {
            $isProjectOpen = $true
            break
        }
    }
}

$escapedTitle = [System.Security.SecurityElement]::Escape($title)
$escapedBody = [System.Security.SecurityElement]::Escape($body)

if ($isProjectOpen) {
    # Clickable + persistent (stays until user dismisses)
    $launchUri = "${editor}://file/$cwd"
    $xml = @"
<toast launch="$launchUri" activationType="protocol" scenario="reminder">
  <visual>
    <binding template="ToastGeneric">
      <text>$escapedTitle</text>
      <text>$escapedBody</text>
    </binding>
  </visual>
  <actions>
    <action content="Dismiss" arguments="dismiss" activationType="system"/>
  </actions>
</toast>
"@
} else {
    # Project not open — persistent, click is a no-op (background activation with no handler)
    $xml = @"
<toast launch="noop" activationType="background" scenario="reminder">
  <visual>
    <binding template="ToastGeneric">
      <text>$escapedTitle</text>
      <text>$escapedBody</text>
    </binding>
  </visual>
  <actions>
    <action content="Dismiss" arguments="dismiss" activationType="system"/>
  </actions>
</toast>
"@
}

[Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument,Windows.Data.Xml.Dom,ContentType=WindowsRuntime] | Out-Null

$xd = New-Object Windows.Data.Xml.Dom.XmlDocument
$xd.LoadXml($xml)
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
$toast = New-Object Windows.UI.Notifications.ToastNotification($xd)
$notifier.Show($toast)
