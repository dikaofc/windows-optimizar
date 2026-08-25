# ================================================
# OX Power Management Module
# ================================================

$PowerPlanGuids = @{
    HighPerformance = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    Balanced        = '381b4222-f694-41f0-9685-ff5bb260df2e'
    PowerSaver      = 'a1841308-3541-4fab-bc81-f71556f20b4a'
    Ultimate        = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
}

function Get-PowerPlan {
    $active = powercfg /getactivescheme
    if ($active -match '({[0-9a-fA-F\-]+})') { return $Matches[1] }
    return $null
}

function Check-PowerPlan {
    $active = Get-PowerPlan
    foreach ($kv in $PowerPlanGuids.GetEnumerator()) {
        if ($kv.Value -eq $active) { return $kv.Key }
    }
    return 'Unknown'
}

function Set-PowerPlan {
    param(
        [string]$Plan = 'High',
        [switch]$DryRun,
        [switch]$AutoConfirm
    )

    $guid = $PowerPlanGuids['HighPerformance']
    if ($PowerPlanGuids.ContainsKey($Plan)) { $guid = $PowerPlanGuids[$Plan] }

    Write-OXLog "Setting power plan to $Plan ($guid)" -Level INFO -Action 'Set-PowerPlan'
    if ($DryRun) {
        Write-Host "  [DRYRUN] Would set power plan to $Plan ($guid)" -ForegroundColor Yellow
        return
    }
    try {
        powercfg /setactive $guid | Out-Null
        Write-Host "  [OK] Power plan set to $Plan" -ForegroundColor Green
        Write-OXLog "Power plan set to $Plan" -Level SUCCESS -Action 'Set-PowerPlan' -Result 'SUCCESS'
    } catch {
        Write-OXLog "Failed to set power plan: $($_.Exception.Message)" -Level ERROR
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restore-PowerPlan {
    param([string]$Plan = 'Balanced', [switch]$DryRun)
    Set-PowerPlan -Plan $Plan -DryRun:$DryRun
}

# Duplicate the hidden "Ultimate Performance" plan from High Performance.
# Reversible: delete the plan with powercfg /delete, or just switch back to Balanced.
function Enable-UltimatePerformance {
    param([switch]$DryRun)
    $guid = $PowerPlanGuids['Ultimate']
    Write-OXLog "Enabling Ultimate Performance plan" -Level INFO -Action 'Enable-UltimatePerformance'
    if ($DryRun) {
        Write-Host '  [DRYRUN] Would enable Ultimate Performance plan.' -ForegroundColor Yellow
        return
    }
    try {
        # /duplicates the High-Perf plan into a new Ultimate plan if not present.
        powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c $guid 2>$null | Out-Null
        powercfg /setactive $guid 2>$null | Out-Null
        Write-Host '  [OK] Ultimate Performance plan enabled.' -ForegroundColor Green
    } catch {
        Write-OXLog "Ultimate plan failed: $($_.Exception.Message)" -Level ERROR
        # Fall back to High Performance.
        Set-PowerPlan -Plan High -DryRun:$false
    }
}

# Disable CPU core parking on AC (keeps all cores awake = snappier on weak CPUs).
# Reversible: set value back to 0 (or restore Balanced plan).
function Disable-CpuParking {
    param([switch]$DryRun)
    $subProc = '54533251-82be-4824-96c1-47b60b740d00'   # SUB_PROCESSOR
    $park    = '0cc5b647-c1df-4637-891a-dec35c318583'   # Processor idle disable (parking)
    Write-OXLog "Disabling CPU parking" -Level INFO -Action 'Disable-CpuParking'
    if ($DryRun) {
        Write-Host '  [DRYRUN] Would disable CPU core parking (AC).' -ForegroundColor Yellow
        return
    }
    try {
        $active = Get-PowerPlan
        if ($active) {
            powercfg /setacvalueindex $active $subProc $park 1 2>$null | Out-Null
            powercfg /setdcvalueindex $active $subProc $park 1 2>$null | Out-Null
            powercfg /setactive $active 2>$null | Out-Null
            Write-Host '  [OK] CPU core parking disabled (AC/DC).' -ForegroundColor Green
        }
    } catch {
        Write-OXLog "CPU parking failed: $($_.Exception.Message)" -Level ERROR
    }
}
