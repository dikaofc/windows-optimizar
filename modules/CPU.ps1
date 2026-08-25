# ================================================
# OX CPU Optimization Module
# ================================================

function Invoke-CPUOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          CPU OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $cpuInfo = Get-CPUInfo
    $vendor = Get-CPUVendor $cpuInfo.Manufacturer

    Write-Host "Detected CPU: $($cpuInfo.Name)" -ForegroundColor White
    Write-Host "Vendor: $vendor" -ForegroundColor White
    Write-Host "Cores: $($cpuInfo.Cores) | Threads: $($cpuInfo.LogicalProcessors)" -ForegroundColor White
    Write-Host ''

    $opts = @(
        @{ ID = 'OX-CPU-001'; Name = 'CPU Power Management'; Description = 'Ultimate/High Performance plan + disable core parking'; Risk = 'LOW' }
    )
    if ($vendor -eq 'Intel') {
        $opts += @{ ID = 'OX-CPU-002'; Name = 'Intel SpeedStep'; Description = 'Ensure SpeedStep enabled in BIOS'; Risk = 'LOW' }
    } elseif ($vendor -eq 'AMD') {
        $opts += @{ ID = 'OX-CPU-003'; Name = "AMD Cool'n'Quiet"; Description = 'Ensure Cool''n''Quiet enabled in BIOS'; Risk = 'LOW' }
    }
    $opts += @{ ID = 'OX-CPU-004'; Name = 'Foreground priority'; Description = 'Favor foreground apps (Win32PrioritySeparation)'; Risk = 'LOW' }

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
        $r = Read-Host 'Apply CPU optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }

    if ($continue) {
        Write-Host 'Applying CPU optimizations...' -ForegroundColor Green
        foreach ($o in $opts) {
            try {
                Write-OXLog "Applying: $($o.Name)" -Level INFO -Optimization $o.ID -Action 'Apply'
                switch ($o.ID) {
                    'OX-CPU-001' {
                        if (Get-Command Enable-UltimatePerformance -ErrorAction SilentlyContinue) {
                            Enable-UltimatePerformance -DryRun:$false
                        } else {
                            Set-PowerPlan -Plan High -DryRun:$false
                        }
                        Disable-CpuParking -DryRun:$false
                    }
                    'OX-CPU-002' { Write-Host '  [INFO] Ensure Intel SpeedStep is enabled in BIOS.' -ForegroundColor Yellow }
                    'OX-CPU-003' { Write-Host "  [INFO] Ensure AMD Cool'n'Quiet is enabled in BIOS." -ForegroundColor Yellow }
                    'OX-CPU-004' {
                        try {
                            Set-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name 'Win32PrioritySeparation' -Value 38 -Type 'DWord' -DryRun:$false
                        } catch {
                            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
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
        Write-Host 'CPU optimization completed!' -ForegroundColor Green
    }
}
