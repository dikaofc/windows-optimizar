@echo off
setlocal EnableDelayedExpansion

:: ================================================
:: OX WINDOWS OPTIMIZER - ALL IN ONE (elevated)
:: Runs every optimization (excluding benchmark) for real.
:: Backup is taken automatically before any change.
:: The Windows Defender removal step will still prompt YES.
:: ================================================
title OX Windows Optimizer - ALL IN ONE
color 0A

set "SCRIPT_DIR=%~dp0"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "MAIN_PS1=%SCRIPT_DIR%OX-Optimizer.ps1"

:: Create logs directory if not exists
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" 2>nul

:: Check Windows 64-bit
if not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    if not "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
        echo This tool is designed for Windows 10 64-bit.
        pause
        exit /b 1
    )
)

:: Self-elevate to Administrator, then run ALL IN ONE for real.
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Requesting Administrator privileges to run ALL IN ONE...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Apply real changes (backup handled inside the engine before MEDIUM/HIGH writes).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MAIN_PS1%" -Command all -Yes
set RC=%errorLevel%

if %RC% neq 0 (
    echo.
    echo [ERROR] The optimizer exited with code %RC%.
    echo Check logs for more information.
    pause
)
exit /b %RC%
