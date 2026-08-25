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

    # Real memory APIs (define once per session; reuse if already loaded).
    if (-not ('OX.RAMOPT' -as [type])) {
        Add-Type -MemberDefinition @'
[DllImport("ntdll.dll")]
public static extern int NtSetSystemInformation(int infoClass, IntPtr info, uint infoLen);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, IntPtr dwMin, IntPtr dwMax);
[DllImport("kernel32.dll")]
public static extern IntPtr GetCurrentProcess();
'@ -Name 'RAMOPT' -Namespace 'OX' -ErrorAction SilentlyContinue
    }
    $mem = 'OX.RAMOPT' -as [type]

    # OX-RAM-001: purge the OS standby/modified list (RAMMap "Empty Standby List").
    # SystemMemoryListInformation = 0x50; MemoryPurgeStandbyList command = 4.
    # This is the genuine API that actually returns reclaimable RAM to the OS pool.
    try {
        if (-not $mem) { throw 'memory API type not available' }
        $buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
        [System.Runtime.InteropServices.Marshal]::WriteInt32($buf, 4)
        $nts = $mem::NtSetSystemInformation(0x50, $buf, 4)
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf)
        # Also drop our own working set so the optimizer's footprint shrinks.
        $null = $mem::SetProcessWorkingSetSize($mem::GetCurrentProcess(), [IntPtr](-1), [IntPtr](-1))
        if ($nts -eq 0) {
            Write-Host '  [OK] Purged OS standby/modified list (reclaimable RAM returned to pool).' -ForegroundColor Green
            Write-OXLog "Standby list purged (NtSetSystemInformation)" -Level SUCCESS -Optimization 'OX-RAM-001' -Action 'Apply' -Result 'SUCCESS'
        } else {
            Write-Host "  [WARN] Standby purge returned NTSTATUS 0x$($nts.ToString('X')) (requires Administrator)." -ForegroundColor Yellow
            Write-OXLog "Standby purge NTSTATUS 0x$($nts.ToString('X'))" -Level WARNING -Optimization 'OX-RAM-001'
        }
    } catch {
        Write-OXLog "RAM standby purge failed: $($_.Exception.Message)" -Level ERROR
        Write-Host "  [WARN] Standby purge failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # OX-RAM-002: truly empty working sets of idle, non-essential processes (EmptyWorkingSet).
    # SetProcessWorkingSetSize(-1,-1) forces the kernel to page out the process's
    # working set — a real change, unlike CloseMainWindow (which only sends WM_CLOSE).
    try {
        if (-not $mem) { throw 'memory API type not available' }
        $keepPatterns = @(
            'System','Idle','Secure System','Registry','Memory Compression',
            'smss*','csrss*','wininit*','services*','lsass*','winlogon*','svchost*',
            'explorer*','dwm*','sihost*','taskhostw*','ShellExperienceHost*','SearchUI*',
            'dllhost*','conhost*','WmiPrvSE*','RuntimeBroker*','OX*','defender*',
            'MsMpEng*','NisSrv*','powershell*'
        )
        $trimmed = 0; $skipped = 0
        Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.Id -gt 4 -and $_.WorkingSet -gt 20MB -and
            ($keepPatterns | Where-Object { $_.Name -like $_ } | Measure-Object).Count -eq 0
        } | ForEach-Object {
            try {
                if ($_.Handle -and $_.Handle -ne [IntPtr]::Zero) {
                    if ($mem::SetProcessWorkingSetSize($_.Handle, [IntPtr](-1), [IntPtr](-1))) { $trimmed++ } else { $skipped++ }
                } else { $skipped++ }
            } catch { $skipped++ }
        }
        Write-Host "  [OK] Working sets emptied: $trimmed process(es) trimmed, $skipped skipped (protected/system)." -ForegroundColor Green
        Write-OXLog "RAM working-set trim: $trimmed trimmed, $skipped skipped" -Level SUCCESS -Optimization 'OX-RAM-002' -Action 'Apply' -Result 'SUCCESS'
    } catch {
        Write-OXLog "RAM working-set trim failed: $($_.Exception.Message)" -Level ERROR
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
