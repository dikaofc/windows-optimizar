# =============================================================
# restore-defender.ps1
# Re-enable Windows Defender + Windows Security.
# Undoes disable-defender.ps1.
# =============================================================

[CmdletBinding()]
param([switch]$Force)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '[ERROR] Run as Administrator.' -ForegroundColor Red
    exit 1
}

if (-not $Force) {
    $r = Read-Host 'Re-enable Windows Defender? [Y/N]'
    if ($r -notmatch '^[Yy]$') { exit 0 }
}

Write-Host 'Re-enabling Windows Defender...' -ForegroundColor Green

# Registry policy OFF
$pol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
try {
    if (Test-Path $pol) {
        Remove-ItemProperty -Path $pol -Name 'DisableAntiSpyware' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $pol -Name 'DisableAntiVirus' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $pol -Name 'DisableSpecialRunningModes' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $pol -Name 'DisableRoutinelyTakingAction' -ErrorAction SilentlyContinue
        $sp = Join-Path $pol 'Spynet'
        Remove-ItemProperty -Path $sp -Name 'SpynetReporting' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $sp -Name 'SubmitSamplesConsent' -ErrorAction SilentlyContinue
    }
    Write-Host '  [OK] Defender policy keys cleared.' -ForegroundColor Green
} catch { Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red }

# Services back to Automatic
$svcs = @{ WinDefend='Automatic'; SecurityHealthService='Automatic'; WdNisSvc='Automatic'; Sense='Manual' }
foreach ($k in $svcs.Keys) {
    try {
        Set-Service -Name $k -StartupType $svcs[$k] -ErrorAction SilentlyContinue
        Start-Service -Name $k -ErrorAction SilentlyContinue
        Write-Host "  [OK] $k -> $($svcs[$k])." -ForegroundColor Green
    } catch { Write-Host "  [WARN] $k : $($_.Exception.Message)" -ForegroundColor Yellow }
}

# Cmdlet re-enable
try {
    if (Get-Command Set-MpPreference -ErrorAction SilentlyContinue) {
        Set-MpPreference -DisableRealtimeMonitoring $false `
                         -DisableBehaviorMonitoring $false `
                         -DisableBlockAtFirstSeen $false `
                         -DisableIOAVProtection $false `
                         -DisableIntrusionPreventionSystem $false `
                         -DisableScriptScanning $false `
                         -DisableArchiveScanning $false `
                         -MAPSReporting Advanced `
                         -ErrorAction SilentlyContinue
    }
    Write-Host '  [OK] Real-time protection re-enabled.' -ForegroundColor Green
} catch {}

# Re-enable tasks
foreach ($tp in @('\Microsoft\Windows\Windows Defender\','\Microsoft\Windows\SecurityHealth\')) {
    try {
        Get-ScheduledTask -TaskPath $tp -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue
    } catch {}
}

# Restore hosts entries
try {
    $hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
    $block = @('fe3.delivery.mp.microsoft.com','wdcp.microsoft.com','wdcpalt.microsoft.com')
    $c = Get-Content $hosts -ErrorAction SilentlyContinue
    $c = $c | Where-Object { -not ($block | Where-Object { $_.Contains($_) }) }
    $c | Set-Content $hosts -Encoding ASCII -ErrorAction SilentlyContinue
} catch {}

Write-Host 'Defender restore complete. Reboot and run a signature update.' -ForegroundColor Green
