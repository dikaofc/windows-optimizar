@echo off
:: restore-defender.bat - launcher with admin self-elevate
cd /d "%~dp0"
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
echo Re-enabling Windows Defender...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-defender.ps1" -Force
pause
