# ================================================
# OX Network Optimization Module
# ================================================

function Invoke-NetworkOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          NETWORK OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $net = Get-NetworkAdapterInfo
    Write-Host 'Network Adapters:' -ForegroundColor White
    foreach ($a in $net) {
        Write-Host "  - $($a.Name) (Link: $($a.LinkSpeed))" -ForegroundColor White
    }
    Write-Host ''

    $opts = @(
        @{ ID = 'OX-NET-001'; Name = 'DNS Cache Flush'; Description = 'Clear DNS resolver cache'; Risk = 'SAFE' },
        @{ ID = 'OX-NET-002'; Name = 'TCP/IP Optimization'; Description = 'Tune TCP parameters'; Risk = 'MEDIUM' },
        @{ ID = 'OX-NET-003'; Name = 'Network Diagnostics'; Description = 'Test connectivity/latency'; Risk = 'SAFE' }
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
        $r = Read-Host 'Apply network optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }

    if ($continue) {
        Write-Host 'Applying network optimizations...' -ForegroundColor Green
        foreach ($o in $opts) {
            try {
                Write-OXLog "Applying: $($o.Name)" -Level INFO -Optimization $o.ID -Action 'Apply'
                switch ($o.ID) {
                    'OX-NET-001' {
                        if (-not $DryRun) { Clear-DnsClientCache }
                        Write-Host '  [OK] DNS cache flushed.' -ForegroundColor Green
                    }
                    'OX-NET-002' {
                        Write-Host '  [INFO] Current TCP settings:' -ForegroundColor Yellow
                        $tcp = Get-NetTCPSetting -ErrorAction SilentlyContinue
                        foreach ($t in $tcp) {
                            Write-Host "    $($t.SettingName): AutoTuning=$($t.AutoTuningLevelLocal), Congestion=$($t.CongestionProvider)" -ForegroundColor DarkGray
                        }
                        if (-not $DryRun) {
                            try {
                                Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal Normal -ErrorAction SilentlyContinue
                                Write-Host '  [OK] TCP AutoTuning set to Normal.' -ForegroundColor Green
                            } catch {
                                Write-Host '  [INFO] TCP tuning requires administrator.' -ForegroundColor Yellow
                            }
                        }
                    }
                    'OX-NET-003' {
                        $endpoints = @('8.8.8.8', '1.1.1.1')
                        foreach ($ep in $endpoints) {
                            try {
                                $ping = Test-Connection -ComputerName $ep -Count 2 -ErrorAction SilentlyContinue
                                if ($ping) {
                                    $lat = ($ping | Measure-Object -Property ResponseTime -Average).Average
                                    Write-Host "  [OK] $ep - Avg latency: $([math]::Round($lat,1))ms" -ForegroundColor Green
                                } else {
                                    Write-Host "  [FAIL] $ep - Unreachable" -ForegroundColor Red
                                }
                            } catch {
                                Write-Host "  [FAIL] $ep - $($_.Exception.Message)" -ForegroundColor Red
                            }
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
        Write-Host 'Network optimization completed!' -ForegroundColor Green
    }
}
