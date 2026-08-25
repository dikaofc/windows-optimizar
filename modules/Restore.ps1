# ================================================
# OX Restore Module
# ================================================

function Invoke-Backup {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          BACKUP SYSTEM' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $Global:OXBackupDir = Join-Path $Script:BackupPath $timestamp
    New-Item -ItemType Directory -Path $Global:OXBackupDir -Force | Out-Null

    Write-Host "Backup directory: $Global:OXBackupDir" -ForegroundColor White
    Write-Host ''

    # 1. Restore point
    Write-Host '[1/4] Creating System Restore Point...' -ForegroundColor Yellow
    $rp = $false
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "OX Optimizer Backup - $timestamp" -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        $rp = $true
        Write-Host '  [OK] System Restore Point created.' -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Restore point could not be created: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # 2. Registry backup
    Write-Host '[2/4] Backing up registry...' -ForegroundColor Yellow
    $regDir = Join-Path $Global:OXBackupDir 'registry'
    Backup-Registry -BackupDir $regDir
    Write-Host '  [OK] Registry backup created.' -ForegroundColor Green

    # 3. Config backup
    Write-Host '[3/4] Backing up configuration...' -ForegroundColor Yellow
    $cfgDir = Join-Path $Global:OXBackupDir 'config'
    New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    Copy-Item (Join-Path $Script:ConfigPath 'settings.json') $cfgDir -Force
    Copy-Item (Join-Path $Script:ConfigPath 'optimizations.json') $cfgDir -Force
    Write-Host '  [OK] Configuration backup created.' -ForegroundColor Green

    # 4. Manifest
    Write-Host '[4/4] Creating manifest...' -ForegroundColor Yellow
    $manifest = @{
        BackupDate           = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        BackupDirectory      = $Global:OXBackupDir
        RestorePointCreated  = $rp
        RegistryBackupPath  = $regDir
        ConfigBackupPath     = $cfgDir
        HardwareInfo         = $Global:OXHardwareInfo
        OptimizationsApplied = @()
    }
    $manifest | ConvertTo-Json -Depth 10 | Out-File (Join-Path $Global:OXBackupDir 'manifest.json') -Encoding UTF8
    Write-Host '  [OK] Manifest created.' -ForegroundColor Green

    Write-Host ''
    Write-Host 'Backup completed successfully!' -ForegroundColor Green
    Write-OXLog 'System backup completed' -Level SUCCESS -Action 'Backup' -Result 'SUCCESS'
}

function Invoke-Restore-Last {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          RESTORE SYSTEM' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $dirs = Get-ChildItem $Script:BackupPath -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($dirs.Count -eq 0) {
        Write-Host 'No backups found.' -ForegroundColor Red
        return
    }

    Write-Host 'Available Backups:' -ForegroundColor White
    $i = 1
    foreach ($b in $dirs) {
        Write-Host "[$i] $($b.Name) - $($b.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        $i++
    }
    Write-Host ''
    $choice = Read-Host 'Select backup to restore (0 to cancel)'
    if ($choice -ne '0' -and $choice -match '^\d+$') {
        $sel = $dirs[$choice - 1]
        if ($sel) {
            Restore-FromDirectory -Directory $sel.FullName
        }
    }
}

function Restore-FromDirectory {
    param([string]$Directory)
    Write-Host "Restoring from: $(Split-Path $Directory -Leaf)" -ForegroundColor Yellow
    $regPath = Join-Path $Directory 'registry'
    if (Test-Path $regPath) {
        Get-ChildItem $regPath -Filter '*.reg' | ForEach-Object {
            reg import $_.FullName 2>$null | Out-Null
            Write-Host "  [OK] Restored: $($_.Name)" -ForegroundColor Green
        }
    }
    $cfgPath = Join-Path $Directory 'config'
    if (Test-Path $cfgPath) {
        Copy-Item (Join-Path $cfgPath 'settings.json') (Join-Path $Script:ConfigPath 'settings.json') -Force
        Copy-Item (Join-Path $cfgPath 'optimizations.json') (Join-Path $Script:ConfigPath 'optimizations.json') -Force
        Write-Host '  [OK] Configuration restored.' -ForegroundColor Green
    }
    Write-Host ''
    Write-Host 'Restore completed! A restart may be required.' -ForegroundColor Green
    Write-OXLog "Restored from $Directory" -Level SUCCESS -Action 'Restore' -Result 'SUCCESS'
}

function Show-BackupRestoreMenu {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          BACKUP / RESTORE' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '[1] Create Backup' -ForegroundColor White
    Write-Host '[2] Restore Last Changes' -ForegroundColor White
    Write-Host '[3] Restore All' -ForegroundColor White
    Write-Host '[4] Restore Specific' -ForegroundColor White
    Write-Host '[0] Back to Main Menu' -ForegroundColor DarkGray
    Write-Host ''

    $choice = Read-Host 'Select'
    switch ($choice) {
        '1' { Invoke-Backup }
        '2' { Invoke-Restore-Last }
        '3' { Invoke-Restore-All }
        '4' { Show-SpecificRestoreMenu }
        '0' { return }
    }
}

function Invoke-Restore-All {
    Write-Host 'Restoring all backups...' -ForegroundColor Yellow
    $dirs = Get-ChildItem $Script:BackupPath -Directory -ErrorAction SilentlyContinue
    foreach ($d in $dirs) { Restore-FromDirectory -Directory $d.FullName }
    Write-Host 'All backups restored!' -ForegroundColor Green
}

function Show-SpecificRestoreMenu {
    Write-Host ''
    Write-Host 'Specific Restore:' -ForegroundColor White
    Write-Host '[1] Restore Registry' -ForegroundColor White
    Write-Host '[2] Restore Services' -ForegroundColor White
    Write-Host '[3] Restore Power Settings' -ForegroundColor White
    Write-Host '[4] Restore Network Settings' -ForegroundColor White
    Write-Host '[0] Back' -ForegroundColor DarkGray
    Write-Host ''

    $choice = Read-Host 'Select'
    switch ($choice) {
        '1' {
            $dirs = Get-ChildItem $Script:BackupPath -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($dirs) { Restore-FromDirectory -Directory $dirs.FullName }
        }
        '3' { Restore-PowerPlan -Plan Balanced }
        default { Write-Host 'No dedicated backup for this category; use full restore.' -ForegroundColor Yellow }
    }
}
