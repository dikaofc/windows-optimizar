@echo off
:: disable-defender.bat - launcher with admin self-elevate
:: Runs disable-defender.ps1 silently as Administrator.
:: SAFETY: this removes your antivirus. Use restore-defender.bat to undo.
title OX Defender Remover
setlocal
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Disabling Windows Defender...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0disable-defender.ps1" -Force
echo.
echo Done. Reboot to finish.
echo Use restore-defender.bat to re-enable Defender.
pause
