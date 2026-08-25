# =============================================================
# disable-defender.ps1
# Disable / remove Windows Defender + Windows Security on Windows 10.
# AUTHOR: user-owned system tuning (kentang-grade).
#
# !! WARNING !! This REMOVES your malware protection. Your PC
# becomes vulnerable to viruses, ransomware, and drive-by attacks.
# Only run this if you have a replacement AV or accept the risk.
# A restore-defender.ps1 is provided to undo everything.
#
# LIMITATIONS (cannot be fully scripted):
#  - TAMPER PROTECTION must be OFF first. Turn it off in:
#    Windows Security > Virus & threat protection > Virus & threat
#    protection settings > Tamper Protection = Off. Without this,
#    the DisableAntiSpyware policy is ignored and Defender re-enables.
#  - On Win10 Pro/Home the Defender *feature* can't be DISM-removed
#    (only Enterprise/Education). The script tries; if it fails it
#    still disables services/tasks/policies.
#  - A later Windows Update may re-enable Defender; re-run or set
#    the policy via Group Policy (see README).
# =============================================================

[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Continue'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host '[ERROR] Run as Administrator (right-click -> Run as admin).' -ForegroundColor Red
    exit 1
}

if (-not $Force) {
    Write-Host ''
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' -ForegroundColor Red
    Write-Host '  THIS DISABLES WINDOWS DEFENDER (YOUR ANTIVIRUS).' -ForegroundColor Red
    Write-Host '  Your PC will be UNPROTECTED against malware.' -ForegroundColor Red
    Write-Host '  Use restore-defender.ps1 to re-enable it.' -ForegroundColor Yellow
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' -ForegroundColor Red
    Write-Host ''
    $r = Read-Host 'Type YES to continue'
    if ($r -ne 'YES') { Write-Host 'Aborted.' -ForegroundColor Yellow; exit 0 }
}

$log = Join-Path $PSScriptRoot 'defender-removal.log'
function Log($m) { "[$(Get-Date -Format 'HH:mm:ss')] $m" | Tee-Object -FilePath $log -Append }

Log '=== Starting Defender disable ==='

# 1) Powershell Defender cmdlet (works only if Tamper Protection is off)
try {
    if (Get-Command Set-MpPreference -ErrorAction SilentlyContinue) {
        Set-MpPreference -DisableRealtimeMonitoring $true `
                         -DisableBehaviorMonitoring $true `
                         -DisableBlockAtFirstSeen $true `
                         -DisableIOAVProtection $true `
                         -DisableIntrusionPreventionSystem $true `
                         -DisableScriptScanning $true `
                         -DisableArchiveScanning $true `
                         -EnableControlledFolderAccess Disabled `
                         -MAPSReporting Disabled `
                         -SubmitSamplesConsent 2 `
                         -SignatureDisableUpdateOnStartupWithoutEngine $true `
                         -ErrorAction Stop
        Log 'Set-MpPreference: realtime/behavior/cloud all disabled.'
    }
} catch { Log "Set-MpPreference failed (Tamper Protection?): $($_.Exception.Message)" }

# 2) Group-policy-style registry keys (most reliable disable lever)
$pol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
try {
    if (-not (Test-Path $pol)) { New-Item -Path $pol -Force | Out-Null }
    New-ItemProperty -Path $pol -Name 'DisableAntiSpyware'      -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $pol -Name 'DisableAntiVirus'        -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $pol -Name 'DisableSpecialRunningModes' -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $pol -Name 'DisableRoutinelyTakingAction' -Value 1 -PropertyType DWord -Force | Out-Null

    $sp = Join-Path $pol 'Spynet'
    if (-not (Test-Path $sp)) { New-Item -Path $sp -Force | Out-Null }
    New-ItemProperty -Path $sp -Name 'SpynetReporting' -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $sp -Name 'SubmitSamplesConsent' -Value 2 -PropertyType DWord -Force | Out-Null
    Log 'Registry policy DisableAntiSpyware=1 applied.'
} catch { Log "Policy reg write failed: $($_.Exception.Message)" }

# 3) Disable Defender services
$svcs = @('WinDefend','SecurityHealthService','WdNisSvc','WdNisDrv','Sense','MsMpSvc')
foreach ($s in $svcs) {
    try {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
        Log "Service ${s} -> Disabled."
    } catch { Log "Service ${s}: $($_.Exception.Message)" }
}

# 4) Disable Defender scheduled tasks (these re-enable scanning)
$taskPaths = @(
    '\Microsoft\Windows\Windows Defender\',
    '\Microsoft\Windows\SecurityHealth\'
)
foreach ($tp in $taskPaths) {
    try {
        Get-ScheduledTask -TaskPath $tp -ErrorAction SilentlyContinue | ForEach-Object {
            Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $tp -ErrorAction SilentlyContinue | Out-Null
            Log "Task disabled: ${tp}$($_.TaskName)"
        }
    } catch { Log "Task path ${tp}: $($_.Exception.Message)" }
}

# 5) Remove the Windows Security app (SecHealthUI) and Defender appx
@('*SecHealthUI*','*WindowsDefender*') | ForEach-Object {
    try {
        Get-AppxPackage -AllUsers $_ -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $_ } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Log "Appx removed: $_"
    } catch { Log "Appx $_ : $($_.Exception.Message)" }
}

# 6) Best-effort DISM feature removal (Enterprise/Education only)
try {
    $feat = Disable-WindowsOptionalFeature -Online -FeatureName Windows-Defender -NoRestart -ErrorAction Stop
    Log "DISM: Windows-Defender feature removed (state: $($feat.RestartNeeded))."
} catch { Log "DISM feature removal skipped (not applicable on this edition): $($_.Exception.Message)" }

# 7) Block Defender's cloud/reputation phone-home via hosts (optional, reversible)
try {
    $hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
    $lines = @('0.0.0.0 fe3.delivery.mp.microsoft.com','0.0.0.0 wdcp.microsoft.com','0.0.0.0 wdcpalt.microsoft.com')
    $content = Get-Content $hosts -ErrorAction SilentlyContinue
    foreach ($l in $lines) {
        if ($content -notcontains $l) { Add-Content -Path $hosts -Value $l -ErrorAction SilentlyContinue }
    }
    Log 'Hosts: Defender telemetry endpoints blocked.'
} catch { Log "Hosts update failed: $($_.Exception.Message)" }

Log '=== Defender disable complete. Reboot to finish. ==='
Write-Host ''
Write-Host 'Done. Reboot required.' -ForegroundColor Green
Write-Host 'If Defender returns after an update, re-run this or apply the' -ForegroundColor Yellow
Write-Host 'Group Policy "Turn off Microsoft Defender Antivirus" = Enabled.' -ForegroundColor Yellow
