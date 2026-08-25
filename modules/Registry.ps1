# ================================================
# OX Registry Backup & Restore Module
# ================================================

function Backup-Registry {
    param([string]$BackupDir)

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $dir = if ($BackupDir) { $BackupDir } else { Join-Path $Global:OXBackupDir "registry_$timestamp" }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    $keys = @(
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM\SYSTEM\CurrentControlSet\Services'
    )

    foreach ($k in $keys) {
        try {
            $f = Join-Path $dir "$($k.Replace('\', '_').Replace(':', '_')).reg"
            $regPath = ConvertTo-RegPath $k
            reg export $regPath $f /y 2>$null | Out-Null
            if (Test-Path $f) {
                Write-OXLog "Registry backup: $f" -Level SUCCESS -Action 'Backup' -Result 'SUCCESS'
            }
        } catch {
            Write-OXLog "Failed registry backup $k - $($_.Exception.Message)" -Level ERROR
        }
    }
    return $dir
}

function Backup-SingleRegistryKey {
    param(
        [Parameter(Mandatory = $true)][string]$KeyPath,
        [string]$BackupDir
    )
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $dir = if ($BackupDir) { $BackupDir } else { Join-Path $Global:OXBackupDir "registry_$timestamp" }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    $f = Join-Path $dir "$($KeyPath.Replace('\', '_').Replace(':', '_')).reg"
    $regPath = ConvertTo-RegPath $KeyPath
    reg export $regPath $f /y 2>$null | Out-Null

    if (Test-Path $f) {
        Write-OXLog "Registry key backup: $f" -Level SUCCESS -Action 'Backup' -Result 'SUCCESS'
        return $f
    }
    return $null
}

function Restore-RegistryKey {
    param([Parameter(Mandatory = $true)][string]$BackupFile)
    if (Test-Path $BackupFile) {
        try {
            reg import $BackupFile 2>$null | Out-Null
            Write-OXLog "Registry restored from $BackupFile" -Level SUCCESS -Action 'Restore' -Result 'SUCCESS'
            return $true
        } catch {
            Write-OXLog "Failed restore $BackupFile - $($_.Exception.Message)" -Level ERROR
            return $false
        }
    }
    Write-OXLog "Backup file not found: $BackupFile" -Level ERROR
    return $false
}

function ConvertTo-RegPath {
    param([string]$KeyPath)
    $map = @{
        'HKLM\' = 'HKEY_LOCAL_MACHINE\'
        'HKCU\' = 'HKEY_CURRENT_USER\'
        'HKCR\' = 'HKEY_CLASSES_ROOT\'
        'HKU\'  = 'HKEY_USERS\'
    }
    foreach ($p in $map.GetEnumerator()) {
        if ($KeyPath.StartsWith($p.Key)) { return $KeyPath.Replace($p.Key, $p.Value) }
    }
    return $KeyPath
}

# Set a registry value, backing up the key first (reversible).
function Set-RegistryValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Value,
        [string]$Type = 'DWord',
        [switch]$DryRun
    )

    Write-OXLog "Setting $Path\$Name = $Value" -Level INFO -Action 'Set-RegistryValue'
    if ($DryRun) {
        Write-Host "  [DRYRUN] Would set $Path\$Name = $Value ($Type)" -ForegroundColor Yellow
        return
    }

    # Backup the containing key before modifying
    try { Backup-SingleRegistryKey -KeyPath $Path } catch {}

    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Write-Host "  [OK] $Path\$Name = $Value" -ForegroundColor Green
}
