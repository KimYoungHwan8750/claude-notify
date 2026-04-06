' Launches notify-hook.ps1 completely hidden (no PowerShell window flash).
' Usage: wscript.exe notify-hook.vbs <json-file>

If WScript.Arguments.Count < 1 Then WScript.Quit 1

Set objShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path = scriptDir & "\notify-hook.ps1"
jsonFile = WScript.Arguments(0)

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & ps1Path & """ """ & jsonFile & """"
' Run hidden (0), don't wait (False)
objShell.Run cmd, 0, False
