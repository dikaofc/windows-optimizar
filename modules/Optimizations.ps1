# ================================================
# OX Optimization Profiles
# ================================================

function Invoke-SafeOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          SAFE OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $tasks = @(
        @{ Name = 'Clean temporary files'; Risk = 'SAFE'; Run = { Invoke-Cleanup -DryRun:$DryRun -AutoConfirm:$true } },
        @{ Name = 'Flush DNS cache'; Risk = 'SAFE'; Run = { Flush-DNSCache -DryRun:$DryRun } },
        @{ Name = 'Empty Recycle Bin'; Risk = 'SAFE'; Run = { Clean-RecycleBin -DryRun:$DryRun | Out-Null } }
    )
    foreach ($t in $tasks) {
        $c = Get-RiskColor $t.Risk
        Write-Host "[$($t.Risk)] $($t.Name)" -ForegroundColor $c
    }
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply safe optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }
    if ($continue) {
        foreach ($t in $tasks) {
            try {
                & $t.Run
                Write-OXLog "Safe opt applied: $($t.Name)" -Level SUCCESS -Action 'Apply' -Result 'SUCCESS'
            } catch {
                Write-OXLog "Safe opt failed: $($t.Name) - $($_.Exception.Message)" -Level ERROR
            }
        }
        Write-Host ''
        Write-Host 'Safe optimization completed!' -ForegroundColor Green
    }
}

function Invoke-GamingOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          GAMING OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $tasks = @(
        @{ Name = 'Enable Game Mode'; Risk = 'LOW' },
        @{ Name = 'Set High Performance power plan'; Risk = 'LOW' },
        @{ Name = 'Clean temporary files'; Risk = 'SAFE' }
    )
    foreach ($t in $tasks) {
        $c = Get-RiskColor $t.Risk
        Write-Host "[$($t.Risk)] $($t.Name)" -ForegroundColor $c
    }
    Write-Host ''
    Write-Host 'Potential improvement varies by system and title.' -ForegroundColor Yellow
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply gaming optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }
    if ($continue) {
        if (-not $DryRun) { Invoke-Backup 2>$null | Out-Null }
        Enable-GameMode -DryRun:$false
        Set-PowerPlan -Plan High -DryRun:$false
        Invoke-Cleanup -DryRun:$false -AutoConfirm:$true
        Write-Host ''
        Write-Host 'Gaming optimization completed!' -ForegroundColor Green
    }
}

function Invoke-PerformanceOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          PERFORMANCE OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $tasks = @(
        @{ Name = 'High Performance power plan'; Risk = 'LOW' },
        @{ Name = 'Clean temporary files'; Risk = 'SAFE' },
        @{ Name = 'Optimize startup programs'; Risk = 'LOW' },
        @{ Name = 'Disable non-essential services'; Risk = 'MEDIUM' }
    )
    foreach ($t in $tasks) {
        $c = Get-RiskColor $t.Risk
        Write-Host "[$($t.Risk)] $($t.Name)" -ForegroundColor $c
    }
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply performance optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }
    if ($continue) {
        if (-not $DryRun) { Invoke-Backup 2>$null | Out-Null }
        Set-PowerPlan -Plan High -DryRun:$false
        Invoke-Cleanup -DryRun:$false -AutoConfirm:$true
        $sp = Get-StartupPrograms
        $enabled = ($sp | Where-Object { $_.Status -eq 'Enabled' }).Count
        if ($enabled -gt 10) {
            Write-Host "  [INFO] $enabled startup items enabled. Review in Startup Manager." -ForegroundColor Yellow
        }
        Write-Host ''
        Write-Host 'Performance optimization completed!' -ForegroundColor Green
    }
}
