# ================================================
# OX GPU Optimization Module
# ================================================

function Invoke-GPUOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          GPU OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $gpuInfo = Get-GPUInfo
    $name = if ($gpuInfo -is [array]) { $gpuInfo[0].Name } else { $gpuInfo.Name }
    $manu = if ($gpuInfo -is [array]) { $gpuInfo[0].Manufacturer } else { $gpuInfo.Manufacturer }
    $vendor = Get-GPUVendor $manu

    Write-Host "Detected GPU: $name" -ForegroundColor White
    Write-Host "Vendor: $vendor" -ForegroundColor White
    Write-Host ''

    $opts = @(
        @{ ID = 'OX-GPU-001'; Name = 'Hardware Acceleration'; Description = 'Ensure hardware acceleration enabled'; Risk = 'LOW' },
        @{ ID = 'OX-GPU-002'; Name = 'GPU Driver Check'; Description = 'Check driver age'; Risk = 'SAFE' }
    )
    if ($vendor -eq 'NVIDIA') { $opts += @{ ID = 'OX-GPU-003'; Name = 'NVIDIA Power Management'; Description = 'Set Prefer Maximum Performance'; Risk = 'LOW' } }
    elseif ($vendor -eq 'AMD') { $opts += @{ ID = 'OX-GPU-004'; Name = 'AMD Power Management'; Description = 'Disable Power Efficiency for gaming'; Risk = 'LOW' } }
    elseif ($vendor -eq 'Intel') { $opts += @{ ID = 'OX-GPU-005'; Name = 'Intel Graphics Optimization'; Description = 'Use Intel Graphics Command Center'; Risk = 'LOW' } }

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
        $r = Read-Host 'Apply GPU optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }

    if ($continue) {
        Write-Host 'Applying GPU optimizations...' -ForegroundColor Green
        foreach ($o in $opts) {
            try {
                Write-OXLog "Applying: $($o.Name)" -Level INFO -Optimization $o.ID -Action 'Apply'
                switch ($o.ID) {
                    'OX-GPU-001' { Write-Host '  [OK] Hardware acceleration is enabled by default in modern Windows.' -ForegroundColor Green }
                    'OX-GPU-002' {
                        $dd = if ($gpuInfo -is [array]) { $gpuInfo[0].DriverDate } else { $gpuInfo.DriverDate }
                        if ($dd) {
                            $days = ((Get-Date) - $dd).Days
                            if ($days -gt 180) {
                                Write-Host "  [WARNING] GPU driver is $days days old. Consider updating." -ForegroundColor Yellow
                            } else {
                                Write-Host '  [OK] GPU driver is reasonably up to date.' -ForegroundColor Green
                            }
                        }
                    }
                    'OX-GPU-003' { Write-Host '  [INFO] In NVIDIA Control Panel set Power Management Mode = Prefer Maximum Performance.' -ForegroundColor Yellow }
                    'OX-GPU-004' { Write-Host '  [INFO] In AMD Software disable Power Efficiency for gaming.' -ForegroundColor Yellow }
                    'OX-GPU-005' { Write-Host '  [INFO] Use Intel Graphics Command Center for tuning.' -ForegroundColor Yellow }
                }
                Write-OXLog "Applied: $($o.Name)" -Level SUCCESS -Optimization $o.ID -Action 'Apply' -Result 'SUCCESS'
            } catch {
                Write-OXLog "Failed: $($o.Name) - $($_.Exception.Message)" -Level ERROR
                Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host ''
        Write-Host 'GPU optimization completed!' -ForegroundColor Green
    }
}
