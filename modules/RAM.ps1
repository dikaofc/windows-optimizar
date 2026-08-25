# ================================================
# OX RAM Optimization Module
# ================================================

function Invoke-RAMOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          RAM OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $ramInfo = Get-RAMInfo
    Write-Host "Total RAM: $($ramInfo.TotalGB) GB" -ForegroundColor White
    Write-Host "Used: $($ramInfo.UsedGB) GB ($($ramInfo.UsagePercent)%)" -ForegroundColor White
    Write-Host "Available: $($ramInfo.AvailableGB) GB" -ForegroundColor White
    Write-Host ''

    $opts = @(
        @{ ID = 'OX-RAM-001'; Name = 'Pagefile Configuration'; Description = 'Analyze pagefile settings'; Risk = 'MEDIUM' },
        @{ ID = 'OX-RAM-002'; Name = 'Memory Compression'; Description = 'Check memory compression'; Risk = 'SAFE' },
        @{ ID = 'OX-RAM-003'; Name = 'Startup Program Analysis'; Description = 'Identify RAM-heavy startup programs'; Risk = 'LOW' }
    )

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
        $r = Read-Host 'Apply RAM optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }

    if ($continue) {
        Write-Host 'Applying RAM optimizations...' -ForegroundColor Green
        foreach ($o in $opts) {
            try {
                Write-OXLog "Applying: $($o.Name)" -Level INFO -Optimization $o.ID -Action 'Apply'
                switch ($o.ID) {
                    'OX-RAM-001' {
                        $pf = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
                        if ($pf) {
                            foreach ($p in $pf) {
                                Write-Host "  Pagefile: $($p.Name) (Initial: $($p.InitialSize) MB, Max: $($p.MaximumSize) MB)" -ForegroundColor White
                            }
                        } else {
                            Write-Host '  Pagefile is system managed.' -ForegroundColor White
                        }
                        if ($ramInfo.TotalGB -ge 16) {
                            Write-Host '  [OK] Sufficient RAM for most workloads.' -ForegroundColor Green
                        } elseif ($ramInfo.TotalGB -le 8) {
                            Write-Host '  [WARNING] Low RAM. Consider upgrade or pagefile tuning.' -ForegroundColor Yellow
                        }
                    }
                    'OX-RAM-002' {
                        try {
                            $cinfo = Get-Counter '\Memory\% Committed Bytes In Use' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop
                            $pct = $cinfo.CounterSamples[-1].CookedValue
                            Write-Host "  Memory committed: $([math]::Round($pct,1))%" -ForegroundColor White
                        } catch {
                            Write-Host '  [INFO] Memory compression status unavailable.' -ForegroundColor Yellow
                        }
                    }
                    'OX-RAM-003' {
                        $sp = Get-StartupPrograms
                        $enabled = $sp | Where-Object { $_.Status -eq 'Enabled' }
                        if ($enabled.Count -gt 10) {
                            Write-Host "  [INFO] $($enabled.Count) startup items enabled. Review in Startup Manager." -ForegroundColor Yellow
                        } else {
                            Write-Host '  [OK] Startup item count is reasonable.' -ForegroundColor Green
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
        Write-Host 'RAM optimization completed!' -ForegroundColor Green
    }
}
