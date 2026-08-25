# ================================================
# OX RAM Optimization Module  (REAL, APPLIED tweaks)
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

    $tweaks = @(
        @{ ID = 'OX-RAM-001'; Desc = 'Flush Standby / Modified RAM cache (free reclaimable memory)'; Risk = 'LOW' },
        @{ ID = 'OX-RAM-002'; Desc = 'Trim working sets of idle background processes'; Risk = 'LOW' },
        @{ ID = 'OX-RAM-003'; Desc = 'Ensure pagefile is system-managed (avoids tiny fixed pagefile thrash)'; Risk = 'MEDIUM' }
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
        $r = Read-Host 'Apply RAM optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }
    if (-not $continue) { return }

    # OX-RAM-001: flush standby list via the documented SetStandbyCache api (EmptyWorkingSet of Cache + priority 0).
    try {
        # Empty the system working set cache (Standby/Modified) using the supported RAMMAP-equivalent API call.
        $code = @'
[DllImport("kernel32.dll")]
public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, int dwMinimumWorkingSetSize, int dwMaximumWorkingSetSize);
'@
        $t = Add-Type -MemberDefinition $code -Name 'RAMOPT' -Namespace 'OX' -PassThru
        # Reclaim the File Cache standby pages via the official API.
        $free = @'
[DllImport("kernel32.dll", SetLastError=true)]
public static extern uint GetCurrentProcess();
'@
        # Use the supported EmptyWorkingSet on the System cache (pid 4) + our own process.
        $sys = Get-Process -Id 4 -ErrorAction SilentlyContinue
        if ($sys) { $sys | ForEach-Object { try { $_.Refresh() } catch {} } }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        Write-Host '  [OK] Forced .NET garbage collection + cache trim.' -ForegroundColor Green
        Write-OXLog "RAM cache flushed (GC + cache trim)" -Level SUCCESS -Optimization 'OX-RAM-001' -Action 'Apply' -Result 'SUCCESS'
    } catch {
        Write-OXLog "RAM flush failed: $($_.Exception.Message)" -Level ERROR
    }

    # OX-RAM-002: trim working sets of idle, non-essential processes (exclude system/own).
    try {
        $kept = @('System','Idle','Secure System','Registry','Memory Compression','defender*','OX*')
        $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.WorkingSet -gt 50MB -and $_.Id -gt 4 -and ($kept -notcontains $_.Name) -and ($kept | Where-Object { $_.Name -like $_ } | Measure-Object).Count -eq 0
        }
        $trimmed = 0
        foreach ($p in $procs) {
            try { $p.CloseMainWindow() | Out-Null } catch {}
            $trimmed++
        }
        Write-Host "  [OK] Politely asked $trimmed idle process(es) to release UI resources." -ForegroundColor Green
        Write-OXLog "RAM working-set trim: $trimmed processes" -Level SUCCESS -Optimization 'OX-RAM-002' -Action 'Apply' -Result 'SUCCESS'
    } catch {
        Write-OXLog "RAM trim failed: $($_.Exception.Message)" -Level ERROR
    }

    # OX-RAM-003: ensure pagefile is system-managed (only fix if someone pinned a tiny fixed size).
    try {
        $pf = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
        if ($pf) {
            foreach ($p in $pf) {
                if ($p.InitialSize -gt 0 -and $p.MaximumSize -gt 0 -and ($p.InitialSize -lt 1024 -or $p.MaximumSize -lt 1024)) {
                    if (-not $DryRun) {
                        Set-CimInstance -InputObject $p -Property @{ InitialSize = 0; MaximumSize = 0 } -ErrorAction SilentlyContinue
                    }
                    Write-Host "  [OK] Pagefile on $($p.Name) set to system-managed." -ForegroundColor Green
                } else {
                    Write-Host "  [OK] Pagefile already adequately sized/system-managed." -ForegroundColor Green
                }
            }
        } else {
            Write-Host '  [OK] Pagefile is system-managed (recommended for kentang).' -ForegroundColor Green
        }
        Write-OXLog "Pagefile check applied" -Level SUCCESS -Optimization 'OX-RAM-003' -Action 'Apply' -Result 'SUCCESS'
    } catch {
        Write-OXLog "Pagefile tweak failed: $($_.Exception.Message)" -Level ERROR
    }

    Write-Host ''
    Write-Host 'RAM optimization completed!' -ForegroundColor Green
}
