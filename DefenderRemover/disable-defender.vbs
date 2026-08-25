' disable-defender.vbs
' Silent launcher for disable-defender.ps1 (no visible PowerShell window).
' Double-click to run, or schedule it. Must be on an admin account.
' WARNING: disables Windows Defender (antivirus). Use restore-defender.vbs to undo.

Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
scriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)
ps1 = FSO.BuildPath(scriptDir, "disable-defender.ps1")

' Self-elevate if not already administrator.
If Not IsAdmin() Then
    Set objShell = CreateObject("Shell.Application")
    objShell.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34), "", "runas", 0
    WScript.Quit
End If

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " & Chr(34) & ps1 & Chr(34) & " -Force"
WshShell.Run cmd, 0, True

Function IsAdmin()
    ' Reliable check: normal users cannot open the HKLM\SAM\SAM key.
    On Error Resume Next
    IsAdmin = False
    Set sh = CreateObject("WScript.Shell")
    sh.RegRead "HKLM\SAM\SAM\Domains"
    IsAdmin = (Err.Number = 0)
    On Error GoTo 0
End Function
