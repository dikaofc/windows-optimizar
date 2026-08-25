# ================================================
# OX Startup Manager Module
# ================================================

function Show-StartupManager {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          STARTUP MANAGER' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $programs = Get-StartupPrograms
    if ($programs.Count -eq 0) {
        Write-Host 'No startup programs found.' -ForegroundColor White
        return
    }

    $i = 1
    foreach ($p in $programs) {
        $c = if ($p.Status -eq 'Enabled') { 'Green' } else { 'DarkGray' }
        Write-Host "[$i] $($p.Name)" -ForegroundColor White
        Write-Host "    Command : $($p.Command)" -ForegroundColor DarkGray
        Write-Host "    Location: $($p.Location)" -ForegroundColor DarkGray
        Write-Host "    Status  : " -NoNewline; Write-Host $p.Status -ForegroundColor $c
        Write-Host ''
        $i++
    }

    Write-Host 'Select item to toggle (0 to exit): ' -NoNewline
    $choice = Read-Host
    if ($choice -ne '0' -and $choice -match '^\d+$') {
        $sel = $programs[$choice - 1]
        if ($sel) {
            if ($sel.Status -eq 'Enabled') {
                Disable-StartupProgram -Name $sel.Name -Location $sel.Location
            } else {
                Enable-StartupProgram -Name $sel.Name -Location $sel.Location -Command $sel.Command
            }
        }
    }
}

function Get-StartupPrograms {
    $list = @()

    # Registry: HKLM/HKCU Run
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    )
    foreach ($rp in $regPaths) {
        if (Test-Path $rp) {
            $props = Get-ItemProperty -Path $rp -ErrorAction SilentlyContinue
            if ($props) {
                $props | Get-Member -MemberType NoteProperty | ForEach-Object {
                    $name = $_.Name
                    if ($name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                        $list += @{
                            Name     = $name
                            Command  = (Get-ItemProperty -Path $rp -Name $name).$name
                            Location = $rp
                            Status   = 'Enabled'
                        }
                    }
                }
            }
        }
    }

    # Startup folders
    $folders = @(
        [System.Environment]::GetFolderPath('CommonStartup'),
        [System.Environment]::GetFolderPath('Startup')
    )
    foreach ($f in $folders) {
        if (Test-Path $f) {
            Get-ChildItem $f -ErrorAction SilentlyContinue | ForEach-Object {
                $list += @{
                    Name     = $_.Name
                    Command  = $_.FullName
                    Location = $f
                    Status   = 'Enabled'
                }
            }
        }
    }
    return $list
}

function Disable-StartupProgram {
    param([string]$Name, [string]$Location)
    Write-OXLog "Disabling startup: $Name" -Level INFO -Action 'Disable-StartupProgram'
    try {
        if ($Location -match 'HKLM:|HKCU:') {
            Backup-SingleRegistryKey -KeyPath $Location | Out-Null
            Remove-ItemProperty -Path $Location -Name $Name -ErrorAction Stop
        } else {
            # Move shortcut out of startup folder, back it up under backups
            $dest = Join-Path $Global:OXBackupDir "disabled-startup"
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
            Move-Item -Path (Join-Path $Location $Name) -Destination $dest -Force
        }
        Write-Host "  [OK] Disabled startup item: $Name" -ForegroundColor Green
    } catch {
        Write-OXLog "Failed disable $Name - $($_.Exception.Message)" -Level ERROR
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Enable-StartupProgram {
    param([string]$Name, [string]$Location, [string]$Command)
    Write-OXLog "Enabling startup: $Name" -Level INFO -Action 'Enable-StartupProgram'
    try {
        if ($Location -match 'HKLM:|HKCU:') {
            New-ItemProperty -Path $Location -Name $Name -Value $Command -PropertyType String -Force | Out-Null
        }
        Write-Host "  [OK] Enabled startup item: $Name" -ForegroundColor Green
    } catch {
        Write-OXLog "Failed enable $Name - $($_.Exception.Message)" -Level ERROR
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}
