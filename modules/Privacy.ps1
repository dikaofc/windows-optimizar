# ================================================
# OX Privacy Module
# ================================================

function Invoke-PrivacyOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          PRIVACY OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $tweaks = @(
        @{ ID = 'OX-PRIV-001'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Value = 0; Risk = 'MEDIUM'; Desc = 'Disable tailored experiences' },
        @{ ID = 'OX-PRIV-002'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Value = 0; Risk = 'MEDIUM'; Desc = 'Disable advertising ID' },
        @{ ID = 'OX-PRIV-003'; Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Value = 1; Type = 'DWord'; Risk = 'MEDIUM'; Desc = 'Limit telemetry (1 = basic)' }
    )

    foreach ($t in $tweaks) {
        $c = Get-RiskColor $t.Risk
        Write-Host "[$($t.ID)] $($t.Desc)" -ForegroundColor White
        Write-Host "  Registry: $($t.Path)\$($t.Name) = $($t.Value)" -ForegroundColor DarkGray
        Write-Host "  Risk: " -NoNewline; Write-Host $t.Risk -ForegroundColor $c
        Write-Host ''
    }

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply privacy optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }

    if ($continue) {
        foreach ($t in $tweaks) {
            try {
                Write-OXLog "Applying privacy tweak $($t.ID)" -Level INFO -Optimization $t.ID -Action 'Apply'
                $type = if ($t.PSObject.Properties['Type']) { $t.Type } else { 'DWord' }
                Set-RegistryValue -Path $t.Path -Name $t.Name -Value $t.Value -Type $type -DryRun:$false
                Write-OXLog "Applied $($t.ID)" -Level SUCCESS -Optimization $t.ID -Action 'Apply' -Result 'SUCCESS'
            } catch {
                Write-OXLog "Failed $($t.ID) - $($_.Exception.Message)" -Level ERROR
                Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host ''
        Write-Host 'Privacy optimization completed!' -ForegroundColor Green
    }
}
