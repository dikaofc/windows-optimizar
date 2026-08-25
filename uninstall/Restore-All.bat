@echo off
title OX Windows Optimizer - Restore All
color 0C
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   OX Windows Optimizer - Restore All
echo ========================================
echo.
echo   This script will restore all Windows settings
echo   that were changed by OX Windows Optimizer.
echo.
echo   WARNING: This will restore registry settings
echo   from the most recent backup.
echo.
echo   A system restart is recommended after restore.
echo.

set /p "_confirm=  Continue with restore? [Y/N]: "
if /i not "!_confirm!"=="Y" (
    echo   Restore cancelled.
    pause
    exit /b
)

echo.
echo Finding latest backup...
echo.

set "BACKUP_DIR=%~dp0..\backups"
set "LATEST_BACKUP="
set "LATEST_DATE="

for /f "tokens=*" %%d in ('dir /b /ad "%BACKUP_DIR%" 2^>nul ^| sort /r') do (
    if not defined LATEST_BACKUP (
        set "LATEST_BACKUP=%BACKUP_DIR%\%%d"
        set "LATEST_DATE=%%d"
    )
)

if not defined LATEST_BACKUP (
    echo   No backups found in %BACKUP_DIR%
    echo.
    echo   To restore manually:
    echo   1. Import .reg files from the backups folder
    echo   2. Reset power plan to Balanced
    echo   3. Restart the computer
    echo.
    pause
    exit /b 1
)

echo   Latest backup: !LATEST_DATE!
echo   Location: !LATEST_BACKUP!
echo.

:: Restore registry files
echo Restoring registry settings...
echo.

set "REG_COUNT=0"
for /f "tokens=*" %%f in ('dir /b /s "!LATEST_BACKUP!\registry\*.reg" 2^>nul') do (
    echo   Importing: %%~nxf
    reg import "%%f" 2>nul
    if !errorlevel! equ 0 (
        echo     [OK]
        set /a REG_COUNT+=1
    ) else (
        echo     [FAILED - may require admin]
    )
)

echo.
echo Registry files restored: !REG_COUNT!
echo.

:: Check for service states
if exist "!LATEST_BACKUP!\services\services.csv" (
    echo   Service states backup found.
    echo   Service states cannot be automatically restored.
    echo   Review services.csv for reference.
    echo.
)

:: Check for power config
if exist "!LATEST_BACKUP!\power\powercfg_query.txt" (
    echo   Power configuration backup found.
    echo   Resetting to Balanced power plan...
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>nul
    if !errorlevel! equ 0 (
        echo     [OK] Power plan set to Balanced
    ) else (
        echo     [Could not reset power plan]
    )
    echo.
)

echo ========================================
echo   Restore Complete
echo ========================================
echo.
echo   A system restart is recommended.
echo.
echo   [Y] Restart now
echo   [N] Restart later
echo.
set /p "_restart=  "
if /i "!_restart!"=="Y" (
    echo   Restarting...
    shutdown /r /t 10 /c "OX Windows Optimizer - Restoring settings"
)

pause
