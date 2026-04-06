param([string]$JsonFile)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"

# Defaults
$editor = "vscode"
$waitingText = "Waiting for input"

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($config.editor) { $editor = $config.editor }
    if ($config.waitingText) { $waitingText = $config.waitingText }
}

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
    $body = $waitingText
}

# Map editor name to Windows process name
$processMap = @{
    "vscode"   = "Code"
    "cursor"   = "Cursor"
    "windsurf" = "Windsurf"
}
$processName = if ($processMap.ContainsKey($editor)) { $processMap[$editor] } else { $editor }

# Check if editor has this project open (by matching window title segments)
$isProjectOpen = $false
$windows = Get-Process -Name $processName -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -ne '' }
foreach ($w in $windows) {
    $segments = $w.MainWindowTitle -split ' - '
    if ($segments -contains $project) {
        $isProjectOpen = $true
        break
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
