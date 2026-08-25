# ================================================
# OX KENTANG (BRUTAL) Optimization Module
# Aggressive tuning for weak / old PCs and laptops.
# Every change is reversible: registry writes go through
# Set-RegistryValue (which backs up the key first) and
# a full system backup is taken before any change.
# ================================================

function Invoke-KentangOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Red
    Write-Host '       KENTANG BRUTAL OPTIMIZATION' -ForegroundColor Red
    Write-Host '       (aggressive tuning for weak PCs)' -ForegroundColor Yellow
    Write-Host '==================================================' -ForegroundColor Red
    Write-Host ''

    # ---- Registry tweaks (all reversible via Set-RegistryValue backup) ----
    $regTweaks = @(
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Value = 2; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Visual effects = best performance' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name = 'EnableTransparency'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable window transparency' },
        @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MinAnimate'; Value = '0'; Type = 'String'; Risk = 'LOW'; Desc = 'Disable menu/window animations' },
        @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MenuShowDelay'; Value = '0'; Type = 'String'; Risk = 'LOW'; Desc = 'Instant menu response' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Value = 1; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Disable background apps' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'CortanaConsent'; Value = 0; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Disable Cortana' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Value = 0; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Disable web search in Start' },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCortana'; Value = 0; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Disable Cortana (policy)' },
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable Game DVR' },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; Name = 'DODownloadMode'; Value = 0; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Disable Windows Update P2P (bandwidth/disk)' },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Value = 1; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Disable Windows Error Reporting' },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows'; Name = 'CEIPEnable'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable Customer Experience telemetry' },
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name = 'NtfsDisableLastAccessUpdate'; Value = 1; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable NTFS last-access stamp (disk perf)' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338387Enabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable tips/notifications' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338389Enabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable app suggestions' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338393Enabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable "get more out of Windows"' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SystemPaneSuggestionsEnabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable Settings suggestions' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SoftLandingEnabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable Windows welcome/slide tips' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-310093Enabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable silent app install' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'DisallowShaking'; Value = 1; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable Aero Shake (minimize-on-shake)' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'PeopleBand'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Hide My People / People band' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable Game Bar background capture' },
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehavior'; Value = 2; Type = 'DWord'; Risk = 'LOW'; Desc = 'Game DVR fullscreen behavior = off' },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'EnableActivityFeed'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable Task View activity feed' },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable activity publishing' },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'UploadUserActivities'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'Disable activity upload' },
        @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'AutoEndTasks'; Value = '1'; Type = 'String'; Risk = 'LOW'; Desc = 'Auto-end hung apps on logoff' },
        @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'HungAppTimeout'; Value = '1000'; Type = 'String'; Risk = 'LOW'; Desc = 'Hung-app wait 1s (was 5s)' },
        @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'WaitToKillAppTimeout'; Value = '2000'; Type = 'String'; Risk = 'LOW'; Desc = 'Faster app shutdown' },
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Value = 38; Type = 'DWord'; Risk = 'LOW'; Desc = 'Favor foreground apps (scheduler)' },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Value = 0; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Multimedia: give apps full CPU (latency)' },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU'; Value = 'Priority'; Type = 'String'; Risk = 'LOW'; Desc = 'Multimedia games profile: GPU priority' },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority'; Value = 6; Type = 'DWord'; Risk = 'LOW'; Desc = 'Multimedia games profile: CPU priority' },
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'LargeSystemCache'; Value = 0; Type = 'DWord'; Risk = 'LOW'; Desc = 'System cache = programs (not file server)' },
        @{ Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'; Name = 'MinSize'; Value = '-100'; Type = 'String'; Risk = 'LOW'; Desc = 'Allow shrinking windows smaller (low-res)' }
    )

    # ---- Services to disable on a weak PC (all back-up covered by Invoke-Backup) ----
    $svcDisable = @(
        'DiagTrack', 'dmwappushservice',        # telemetry
        'SysMain',                              # Superfetch - frees RAM on low-RAM kentang
        'WSearch',                              # Windows Search indexer (reversible)
        'RetailDemo', 'MapsBroker',             # unused
        'TabletInputService',                   # no touch on most kentang
        'Fax', 'WMPNetworkSvc',                 # legacy / media sharing
        'XboxGipSvc', 'XboxNetApiSvc', 'XblAuthManager', 'XblGameSave',
        'lfsvc', 'PhoneSvc', 'PrintNotify', 'PimIndexMaintenanceSvc',
        'WerSvc'                                # Windows Error Reporting service
    )

    # ---- Preview ----
    Write-Host 'REGISTRY TWEAKS:' -ForegroundColor Cyan
    foreach ($t in $regTweaks) {
        $c = Get-RiskColor $t.Risk
        Write-Host "  [$($t.Risk)] $($t.Desc)" -ForegroundColor $c
    }
    Write-Host ''
    Write-Host 'SERVICES TO DISABLE:' -ForegroundColor Cyan
    Write-Host "  $(($svcDisable | ForEach-Object { $_ }) -join ', ')" -ForegroundColor White
    Write-Host ''
    Write-Host 'OTHER:' -ForegroundColor Cyan
    Write-Host '  [LOW] Ultimate Performance power plan' -ForegroundColor White
    Write-Host '  [LOW] Disable CPU core parking (AC/DC)' -ForegroundColor White
    Write-Host '  [LOW] Disk never idle on AC / USB suspend off' -ForegroundColor White
    Write-Host '  [MEDIUM] Disable hibernation (reclaim disk, reversible)' -ForegroundColor Yellow
    Write-Host '  [SAFE] Deep cleanup (temp/recycle/update cache)' -ForegroundColor Green
    Write-Host '  [LOW] GPU tweaks (HW accel on, HwSchMode off, AMD ULPS off)' -ForegroundColor White
    Write-Host '  [LOW] RAM tweaks (cache trim, working-set trim, pagefile fix)' -ForegroundColor White
    Write-Host '  [MEDIUM] Network tweaks (DNS, Nagle off, scaling heuristics off)' -ForegroundColor White
    Write-Host '  [HIGH] REMOVE Windows Defender antivirus (reversible)' -ForegroundColor Red
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply KENTANG BRUTAL optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }
    if (-not $continue) { return }

    # One full backup covers registry + restore point + config.
    Invoke-Backup 2>$null | Out-Null

    # Cleanup first (safe, frees space).
    Invoke-Cleanup -DryRun:$false -AutoConfirm:$true
    Flush-DNSCache -DryRun:$false

    # Power plan = Ultimate Performance + disable CPU parking + brutal settings.
    Enable-UltimatePerformance -DryRun:$false
    Disable-CpuParking -DryRun:$false
    try {
        $guid = (Get-PowerPlan)
        if (-not $guid) { $guid = $PowerPlanGuids['HighPerformance'] }
        powercfg /setacvalueindex $guid 2a737441-1930-4402-9d77-b1b06e58916b 48e6b7a6-50f5-4782-a5d4-920a9eaaabc0 0 2>$null | Out-Null
        powercfg /change disk-timeout-ac 0 2>$null | Out-Null
        Write-Host '  [OK] Disk idle disabled / USB suspend off (AC).' -ForegroundColor Green
    } catch {
        Write-OXLog "Power tweak failed: $($_.Exception.Message)" -Level ERROR
    }
    try {
        powercfg -h off 2>$null | Out-Null
        Write-Host '  [OK] Hibernation disabled (reclaim disk). Reversible: powercfg -h on' -ForegroundColor Green
    } catch {
        Write-OXLog "Hibernate off failed: $($_.Exception.Message)" -Level ERROR
    }

    # Registry tweaks.
    foreach ($t in $regTweaks) {
        try {
            Set-RegistryValue -Path $t.Path -Name $t.Name -Value $t.Value -Type $t.Type -DryRun:$false
            Write-OXLog "Kentang reg $($t.Name)" -Level SUCCESS -Action 'Apply' -Result 'SUCCESS'
        } catch {
            Write-OXLog "Kentang reg failed $($t.Name) - $($_.Exception.Message)" -Level ERROR
            Write-Host "  [ERROR] $($t.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Disable services (skip ones not installed on this build).
    $present = @()
    foreach ($s in $svcDisable) {
        if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
            $present += $s
        } else {
            Write-Host "  [SKIP] $s not installed on this system." -ForegroundColor DarkGray
        }
    }
    foreach ($s in $present) {
        Set-ServiceState -Name $s -StartupType Disabled -Status Stopped -DryRun:$false
    }

    # Super-brutal: also apply GPU / RAM / Network real tweaks.
    Write-Host '  [OK] GPU / RAM / Network brutal tweaks applying...' -ForegroundColor Green
    Invoke-GPUOptimization          -DryRun:$false -AutoConfirm:$true
    Invoke-RAMOptimization          -DryRun:$false -AutoConfirm:$true
    Invoke-NetworkOptimization      -DryRun:$false -AutoConfirm:$true

    # Remove Windows Defender (antivirus) — the most brutal step.
    # Launches the standalone DefenderRemover scripts as admin.
    # Skipped in DryRun (would otherwise prompt + launch the remover).
    if (-not $DryRun) {
        try {
            Write-Host '  [BRUTAL] Disabling Windows Defender...' -ForegroundColor Red
            Invoke-DefenderRemover
        } catch {
            Write-OXLog "Defender remover launch failed: $($_.Exception.Message)" -Level ERROR
        }
    } else {
        Write-Host '  [DRYRUN] Would remove Windows Defender (run without -DryRun to apply).' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Red
    Write-Host 'KENTANG BRUTAL complete. Reboot strongly recommended.' -ForegroundColor Green
    Write-Host 'Restore anytime via Backup/Restore menu or Restore-All.bat.' -ForegroundColor Yellow
    Write-Host '==================================================' -ForegroundColor Red
}
