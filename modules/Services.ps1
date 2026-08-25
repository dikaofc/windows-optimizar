# ================================================
# OX Services Manager Module
# ================================================

function Show-ServicesManager {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          SERVICES MANAGER' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $services = Get-OptimizableServices
    Write-Host 'Potentially Optimizable Services:' -ForegroundColor White
    Write-Host ''

    $i = 1
    foreach ($s in $services) {
        $c = Get-RiskColor $s.Risk
        Write-Host "[$i] $($s.Name) [$($s.Status)/$($s.StartType)]" -ForegroundColor White
        Write-Host "     Risk: " -NoNewline; Write-Host $s.Risk -ForegroundColor $c
        Write-Host "     Recommendation: $($s.Recommendation)" -ForegroundColor Yellow
        Write-Host ''
        $i++
    }

    Write-Host 'Select service to toggle (0 to exit): ' -NoNewline
    $choice = Read-Host
    if ($choice -ne '0' -and $choice -match '^\d+$') {
        $sel = $services[$choice - 1]
        if ($sel) {
            Write-Host ''
            Write-Host "Service: $($sel.Name) [$($sel.Status)/$($sel.StartType)]" -ForegroundColor White
            $action = Read-Host 'Action: [1] Enable [2] Disable [3] Manual [0] Cancel'
            switch ($action) {
                '1' { Set-ServiceState -Name $sel.Name -StartupType Automatic -Status Running -DryRun:$Global:OXDryRun }
                '2' { Set-ServiceState -Name $sel.Name -StartupType Disabled -Status Stopped -DryRun:$Global:OXDryRun }
                '3' { Set-ServiceState -Name $sel.Name -StartupType Manual -DryRun:$Global:OXDryRun }
                default { Write-Host 'Cancelled.' -ForegroundColor Yellow }
            }
        }
    }
}

function Get-OptimizableServices {
    $list = @(
        @{ Name = 'DiagTrack';              Risk = 'SAFE';     Category = 'Telemetry'; Recommendation = 'Can be disabled for privacy' },
        @{ Name = 'dmwappushservice';       Risk = 'SAFE';     Category = 'Telemetry'; Recommendation = 'Can be disabled for privacy' },
        @{ Name = 'SysMain';                Risk = 'OPTIONAL'; Category = 'Performance'; Recommendation = 'Disable if on SSD for snappier feel' },
        @{ Name = 'WSearch';                Risk = 'OPTIONAL'; Category = 'Search'; Recommendation = 'Disable if Windows Search unused' },
        @{ Name = 'Fax';                    Risk = 'SAFE';     Category = 'Legacy'; Recommendation = 'Legacy service, rarely needed' },
        @{ Name = 'TabletInputService';     Risk = 'SAFE';     Category = 'Tablet'; Recommendation = 'Disable on non-touch devices' },
        @{ Name = 'WMPNetworkSvc';          Risk = 'SAFE';     Category = 'Media'; Recommendation = 'Disable if not sharing media' },
        @{ Name = 'XblAuthManager';         Risk = 'OPTIONAL'; Category = 'Xbox'; Recommendation = 'Disable if Xbox unused' },
        @{ Name = 'XblGameSave';            Risk = 'OPTIONAL'; Category = 'Xbox'; Recommendation = 'Disable if Xbox unused' },
        @{ Name = 'XboxNetApiSvc';          Risk = 'OPTIONAL'; Category = 'Xbox'; Recommendation = 'Disable if Xbox unused' },
        @{ Name = 'XboxGipSvc';             Risk = 'OPTIONAL'; Category = 'Xbox'; Recommendation = 'Disable if Xbox unused' },
        @{ Name = 'MapsBroker';             Risk = 'SAFE';     Category = 'Maps'; Recommendation = 'Disable if Maps unused' },
        @{ Name = 'RetailDemo';             Risk = 'SAFE';     Category = 'Demo'; Recommendation = 'Disable on production PCs' },
        @{ Name = 'lfsvc';                  Risk = 'OPTIONAL'; Category = 'Location'; Recommendation = 'Disable if location unused' },
        @{ Name = 'PhoneSvc';               Risk = 'OPTIONAL'; Category = 'Phone'; Recommendation = 'Disable if no phone link' },
        @{ Name = 'PrintNotify';            Risk = 'OPTIONAL'; Category = 'Printing'; Recommendation = 'Disable if no printer' },
        @{ Name = 'PimIndexMaintenanceSvc'; Risk = 'OPTIONAL'; Category = 'Contacts'; Recommendation = 'Disable if not used' }
    )

    $result = @()
    foreach ($info in $list) {
        $svc = Get-Service -Name $info.Name -ErrorAction SilentlyContinue
        if ($svc) {
            $result += @{
                Name           = $info.Name
                Risk           = $info.Risk
                Category       = $info.Category
                Recommendation = $info.Recommendation
                Status         = $svc.Status
                StartType      = $svc.StartType
            }
        }
    }
    return $result
}

function Set-ServiceState {
    param(
        [string]$Name,
        [string]$StartupType,
        [string]$Status,
        [switch]$DryRun
    )
    Write-OXLog "Service $Name -> $StartupType" -Level INFO -Action 'Set-ServiceState'
    if ($DryRun) {
        Write-Host "  [DRYRUN] Would set $Name to $StartupType" -ForegroundColor Yellow
        return
    }
    try {
        Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
        if ($Status -eq 'Stopped') { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue }
        if ($Status -eq 'Running') { Start-Service -Name $Name -ErrorAction SilentlyContinue }
        Write-Host "  [OK] $Name set to $StartupType." -ForegroundColor Green
    } catch {
        Write-OXLog "Failed service $Name - $($_.Exception.Message)" -Level ERROR
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}
