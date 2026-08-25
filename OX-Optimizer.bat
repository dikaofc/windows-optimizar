@echo off
setlocal EnableDelayedExpansion

:: ================================================
:: OX WINDOWS OPTIMIZER - Main Launcher
:: ================================================
title OX Windows Optimizer
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

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [WARNING] Administrator privileges required for full functionality.
    echo.
    choice /C YN /M "Restart as Administrator?"
    if errorlevel 2 goto :eof
    if errorlevel 1 (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
        exit /b
    )
)

:: Pass arguments to PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MAIN_PS1%" %*

if errorlevel 1 (
    echo.
    echo [ERROR] The optimizer exited with an error.
    echo Check logs for more information.
    pause
)

exit /b %errorLevel%
