# ================================================
# OX Storage Optimization Module
# ================================================

function Invoke-StorageOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          STORAGE OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $sys = Get-SystemDrive

    Write-Host "System Drive: $($sys.Drive)" -ForegroundColor White
    Write-Host "Storage Type: $($sys.Type)" -ForegroundColor White
    Write-Host "Free Space: $($sys.FreeSpaceGB) GB / $($sys.SizeGB) GB" -ForegroundColor White
    Write-Host ''

    $opts = @()
    if ($sys.Type -match 'SSD|NVMe') {
        $opts += @{ ID = 'OX-STORE-001'; Name = 'TRIM Verification'; Description = 'Check/enable TRIM for SSD'; Risk = 'SAFE' }
    } elseif ($sys.Type -eq 'HDD') {
        $opts += @{ ID = 'OX-STORE-002'; Name = 'Defragmentation'; Description = 'Defragment HDD'; Risk = 'MEDIUM' }
    }
    $opts += @{ ID = 'OX-STORE-003'; Name = 'Storage Cleanup'; Description = 'Clean temp/unnecessary files'; Risk = 'SAFE' }
    $opts += @{ ID = 'OX-STORE-004'; Name = 'Storage Health Check'; Description = 'Check disk health'; Risk = 'SAFE' }

    foreach ($o in $opts) {
        $c = Get-RiskColor $o.Risk
        Write-Host "[$($o.ID)] $($o.Name)" -ForegroundColor White
        Write-Host "  Description: $($o.Description)" -ForegroundColor DarkGray
        Write-Host "  Risk: " -NoNewline; Write-Host $o.Risk -ForegroundColor $c
        Write-Host ''
    }

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply storage optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }

    if ($continue) {
        Write-Host 'Applying storage optimizations...' -ForegroundColor Green
        foreach ($o in $opts) {
            try {
                Write-OXLog "Applying: $($o.Name)" -Level INFO -Optimization $o.ID -Action 'Apply'
                switch ($o.ID) {
                    'OX-STORE-001' {
                        if (-not $DryRun) {
                            $trim = fsutil behavior query DisableDeleteNotify
                            if ($trim -notmatch 'DisableDeleteNotify = 0') {
                                Write-Host '  [OK] TRIM enabled.' -ForegroundColor Green
                                if (-not $DryRun) { fsutil behavior set DisableDeleteNotify 0 | Out-Null }
                            } else {
                                Write-Host '  [OK] TRIM already enabled.' -ForegroundColor Green
                            }
                            $letter = $sys.Drive.TrimEnd(':')
                            Optimize-Volume -DriveLetter $letter -ReTrim -ErrorAction SilentlyContinue
                        }
                    }
                    'OX-STORE-002' {
                        $letter = $sys.Drive.TrimEnd(':')
                        Write-Host "  Running defrag on $letter ..." -ForegroundColor Yellow
                        if (-not $DryRun) { Optimize-Volume -DriveLetter $letter -Defrag -ErrorAction SilentlyContinue }
                    }
                    'OX-STORE-003' {
                        $cleaned = Clean-TempFiles -DryRun:$DryRun
                        Write-Host "  [OK] Cleaned $cleaned MB of temporary files." -ForegroundColor Green
                    }
                    'OX-STORE-004' {
                        $disks = Get-CimInstance Win32_DiskDrive | Where-Object { $_.Status -eq 'OK' }
                        foreach ($d in $disks) {
                            Write-Host "  Drive: $($d.Model) [$($d.Status)]" -ForegroundColor White
                        }
                    }
                }
                Write-OXLog "Applied: $($o.Name)" -Level SUCCESS -Optimization $o.ID -Action 'Apply' -Result 'SUCCESS'
            } catch {
                Write-OXLog "Failed: $($o.Name) - $($_.Exception.Message)" -Level ERROR
                Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host ''
        Write-Host 'Storage optimization completed!' -ForegroundColor Green
        Write-Host 'Note: Defragmentation is only run on HDDs, never on SSDs.' -ForegroundColor Yellow
    }
}

function Get-SystemDrive {
    $letter = $env:SystemDrive
    $logical = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $letter }
    $physical = Get-CimInstance Win32_DiskDrive | Select-Object -First 1
    return @{
        Drive        = $letter
        FileSystem   = $logical.FileSystem
        SizeGB       = [math]::Round($logical.Size / 1GB, 2)
        FreeSpaceGB  = [math]::Round($logical.FreeSpace / 1GB, 2)
        UsedSpaceGB  = [math]::Round(($logical.Size - $logical.FreeSpace) / 1GB, 2)
        VolumeName   = $logical.VolumeName
        Type         = Get-StorageType $physical
    }
}
