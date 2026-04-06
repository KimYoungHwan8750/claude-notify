param([string]$JsonFile)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"

# Load editor from config (default: vscode)
$editor = "vscode"
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($config.editor) { $editor = $config.editor }
}

$json = Get-Content $JsonFile -Raw -Encoding UTF8 | ConvertFrom-Json

$project = Split-Path $json.cwd -Leaf
$cwd = $json.cwd -replace '\\', '/'

$msg = $json.last_assistant_message
if ($msg.Length -gt 80) {
    $msg = $msg.Substring(0, 80) + "..."
}

$event = $json.hook_event_name

if ($event -eq "Stop") {
    $title = "Claude Code [$project]"
    $body = $msg
} else {
    $title = "Claude Code [$project]"
    $body = "Waiting for input"
}

$launchUri = "${editor}://file/$cwd"
$escapedTitle = [System.Security.SecurityElement]::Escape($title)
$escapedBody = [System.Security.SecurityElement]::Escape($body)

$xml = @"
<toast launch="$launchUri" activationType="protocol">
  <visual>
    <binding template="ToastGeneric">
      <text>$escapedTitle</text>
      <text>$escapedBody</text>
    </binding>
  </visual>
</toast>
"@

[Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument,Windows.Data.Xml.Dom,ContentType=WindowsRuntime] | Out-Null

$xd = New-Object Windows.Data.Xml.Dom.XmlDocument
$xd.LoadXml($xml)
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
$toast = New-Object Windows.UI.Notifications.ToastNotification($xd)
$notifier.Show($toast)
