' restore-defender.vbs
' Silent launcher for restore-defender.ps1. Re-enables Windows Defender.

Set FSO = CreateObject("Scripting.FileSystemObject")
scriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)
ps1 = FSO.BuildPath(scriptDir, "restore-defender.ps1")

If Not IsAdmin() Then
    Set objShell = CreateObject("Shell.Application")
    objShell.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34), "", "runas", 0
    WScript.Quit
End If

Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " & Chr(34) & ps1 & Chr(34) & " -Force", 0, True

Function IsAdmin()
    On Error Resume Next
    IsAdmin = False
    Set sh = CreateObject("WScript.Shell")
    sh.RegRead "HKLM\SAM\SAM\Domains"
    IsAdmin = (Err.Number = 0)
    On Error GoTo 0
End Function
