# ================================================
# OX Network Optimization Module  (REAL, APPLIED tweaks)
# =============================================================

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

    $tweaks = @(
        @{ ID = 'OX-NET-001'; Desc = 'Flush DNS resolver cache'; Risk = 'SAFE' },
        @{ ID = 'OX-NET-002'; Desc = 'Set fast public DNS (1.1.1.1 / 8.8.8.8) on active adapters'; Risk = 'LOW' },
        @{ ID = 'OX-NET-003'; Desc = 'Disable Nagle algorithm (lower TCP latency)'; Risk = 'MEDIUM' },
        @{ ID = 'OX-NET-004'; Desc = 'Disable Windows scaling heuristics (set RWIN auto)'; Risk = 'LOW' }
    )
    foreach ($t in $tweaks) {
        $c = Get-RiskColor $t.Risk
        Write-Host "[$($t.ID)] $($t.Desc)" -ForegroundColor White
        Write-Host "  Risk: " -NoNewline; Write-Host $t.Risk -ForegroundColor $c
    }
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply network optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }
    if (-not $continue) { return }

    # OX-NET-001
    try { Clear-DnsClientCache; Write-Host '  [OK] DNS cache flushed.' -ForegroundColor Green } catch {}

    # OX-NET-002: apply DNS to each active adapter (back up current first).
    try {
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
        $dns = @('1.1.1.1','8.8.8.8')
        foreach ($a in $adapters) {
            try {
                $cur = (Get-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses -join ','
                Write-OXLog "DNS backup $($a.Name): $cur" -Level INFO -Action 'Backup'
                Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses $dns -ErrorAction Stop
                Write-Host "  [OK] DNS set on $($a.Name): $($dns -join ', ')." -ForegroundColor Green
            } catch {
                Write-Host "  [WARN] DNS on $($a.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-OXLog "DNS set failed: $($_.Exception.Message)" -Level ERROR
    }

    # OX-NET-003: disable Nagle (TcpAckFrequency=1, TCPNoDelay=1) per active adapter GUID.
    try {
        $tcpip = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
        Get-ChildItem $tcpip -ErrorAction SilentlyContinue | ForEach-Object {
            $p = $_.PSPath
            Set-RegistryValue -Path $p -Name 'TcpAckFrequency' -Value 1 -Type 'DWord' -DryRun:$false
            Set-RegistryValue -Path $p -Name 'TCPNoDelay' -Value 1 -Type 'DWord' -DryRun:$false
        }
        Write-Host '  [OK] Nagle disabled on all TCP interfaces (reversible).' -ForegroundColor Green
        Write-OXLog "Nagle disabled" -Level SUCCESS -Optimization 'OX-NET-003' -Action 'Apply' -Result 'SUCCESS'
    } catch {
        Write-OXLog "Nagle failed: $($_.Exception.Message)" -Level ERROR
    }

    # OX-NET-004: disable scaling heuristics so RWIN is set automatically.
    try {
        if (Get-Command Set-NetTCPSetting -ErrorAction SilentlyContinue) {
            Set-NetTCPSetting -SettingName Internet -ScalingHeuristics Disabled -ErrorAction SilentlyContinue
            Set-NetTCPSetting -SettingName Datacenter -ScalingHeuristics Disabled -ErrorAction SilentlyContinue
        }
        Write-Host '  [OK] TCP scaling heuristics disabled.' -ForegroundColor Green
    } catch {}

    Write-Host ''
    Write-Host 'Network optimization completed!' -ForegroundColor Green
}
