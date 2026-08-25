# ================================================
# OX Utility Functions
# ================================================

function Get-RiskColor {
    param([string]$Risk)
    switch ($Risk.ToUpper()) {
        'SAFE'      { return 'Green' }
        'LOW'       { return 'Yellow' }
        'MEDIUM'    { return 'DarkYellow' }
        'HIGH'      { return 'Red' }
        'ADVANCED'  { return 'Magenta' }
        'OPTIONAL'  { return 'Cyan' }
        default     { return 'Gray' }
    }
}

function Show-SystemInformation {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          SYSTEM INFORMATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $hw = $Global:OXHardwareInfo
    if (-not $hw) { $hw = Get-HardwareInfo }

    Write-Host '=== OPERATING SYSTEM ===' -ForegroundColor Yellow
    Write-Host "OS: $($hw.OS.OSName) $($hw.OS.Architecture)" -ForegroundColor White
    Write-Host "Build: $($hw.OS.Build)" -ForegroundColor White
    Write-Host ''
    Write-Host '=== CPU ===' -ForegroundColor Yellow
    Write-Host "Processor: $($hw.CPU.Name)" -ForegroundColor White
    Write-Host "Cores: $($hw.CPU.Cores) | Threads: $($hw.CPU.LogicalProcessors)" -ForegroundColor White
    Write-Host ''
    Write-Host '=== MEMORY ===' -ForegroundColor Yellow
    Write-Host "Total RAM: $($hw.RAM.TotalGB) GB" -ForegroundColor White
    Write-Host "Used: $($hw.RAM.UsedGB) GB ($($hw.RAM.UsagePercent)%)" -ForegroundColor White
    Write-Host ''
    Write-Host '=== GPU ===' -ForegroundColor Yellow
    if ($hw.GPU -is [array]) {
        foreach ($g in $hw.GPU) { Write-Host "GPU: $($g.Name) (Driver: $($g.DriverVersion))" -ForegroundColor White }
    } else {
        Write-Host "GPU: $($hw.GPU.Name) (Driver: $($hw.GPU.DriverVersion))" -ForegroundColor White
    }
    Write-Host ''
    Write-Host '=== STORAGE ===' -ForegroundColor Yellow
    foreach ($s in $hw.Storage) {
        if ($s.Drive) {
            Write-Host "Drive $($s.Drive): $($s.FileSystem), $($s.FreeSpaceGB)/$($s.SizeGB) GB free" -ForegroundColor White
        } elseif ($s.Model) {
            Write-Host "Disk: $($s.Model) [$($s.Type)]" -ForegroundColor White
        }
    }
}

function Analyze-System {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          SYSTEM ANALYSIS' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $hw = $Global:OXHardwareInfo
    if (-not $hw) { $hw = Get-HardwareInfo }

    $analysis = @{
        OS      = $hw.OS
        CPU     = $hw.CPU
        GPU     = $hw.GPU
        RAM     = $hw.RAM
        Storage = $hw.Storage
        Recommendations = @()
    }

    Write-Host "OS: $($hw.OS.OSName) $($hw.OS.Architecture)" -ForegroundColor White
    Write-Host "CPU: $($hw.CPU.Name)" -ForegroundColor White
    Write-Host "GPU: $(if ($hw.GPU -is [array]) { $hw.GPU[0].Name } else { $hw.GPU.Name })" -ForegroundColor White
    Write-Host "RAM: $($hw.RAM.TotalGB) GB ($($hw.RAM.UsagePercent)% used)" -ForegroundColor White

    $sys = $hw.Storage | Where-Object { $_.Drive -eq $env:SystemDrive }
    if ($sys) { Write-Host "Storage: $($sys.Type) drive, $($sys.FreeSpaceGB) GB free" -ForegroundColor White }
    Write-Host ''

    $startup = Get-StartupPrograms
    $enabled = $startup | Where-Object { $_.Status -eq 'Enabled' }
    $tempFolders = @($env:TEMP, "$env:SystemRoot\Temp")
    $tempSize = 0
    foreach ($f in $tempFolders) {
        if (Test-Path $f) {
            $files = Get-ChildItem $f -File -Recurse -ErrorAction SilentlyContinue
            if ($files) {
                $tempSize += ($files | Measure-Object -Property Length -Sum).Sum
            }
        }
    }

    Write-Host 'STARTUP' -ForegroundColor Yellow
    Write-Host "$($enabled.Count) enabled items" -ForegroundColor White
    Write-Host ''
    Write-Host 'TEMP FILES' -ForegroundColor Yellow
    Write-Host "$([math]::Round($tempSize / 1GB, 2)) GB" -ForegroundColor White
    Write-Host ''

    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host 'RECOMMENDATIONS' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $recs = @()
    if ([math]::Round($tempSize / 1GB, 2) -gt 1) { $recs += @{ Risk = 'SAFE'; Description = 'Clean temporary files' } }
    if ($enabled.Count -gt 10) { $recs += @{ Risk = 'SAFE'; Description = 'Review startup programs' } }
    if ($hw.RAM.UsagePercent -gt 80) { $recs += @{ Risk = 'LOW'; Description = 'Consider RAM upgrade or reduce background processes' } }
    if ($sys -and $sys.FreeSpaceGB -lt 10) { $recs += @{ Risk = 'MEDIUM'; Description = 'Low disk space; clean up or add storage' } }

    foreach ($r in $recs) {
        $c = Get-RiskColor $r.Risk
        Write-Host "[$($r.Risk)]" -ForegroundColor $c -NoNewline
        Write-Host " $($r.Description)" -ForegroundColor White
    }
    if ($recs.Count -eq 0) { Write-Host 'No immediate recommendations. System looks healthy.' -ForegroundColor Green }

    $analysis.Recommendations = $recs
    return $analysis
}

function Show-Logs {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          LOG VIEWER' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''
    if (Test-Path $Global:OXLogFile) {
        Get-Content $Global:OXLogFile -Tail 50 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
    } else {
        Write-Host 'No log file found.' -ForegroundColor Yellow
    }
}

function Invoke-Benchmark {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          BENCHMARK (reporting)' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $hw = $Global:OXHardwareInfo
    if (-not $hw) { $hw = Get-HardwareInfo }

    $report = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        CPU       = $hw.CPU.Name
        Cores     = $hw.CPU.LogicalProcessors
        RAM_GB    = $hw.RAM.TotalGB
        UsedPct   = $hw.RAM.UsagePercent
        BootTime  = $hw.OS.LastBoot
    }

    Write-Host "CPU: $($report.CPU)" -ForegroundColor White
    Write-Host "Logical processors: $($report.Cores)" -ForegroundColor White
    Write-Host "RAM: $($report.RAM_GB) GB ($($report.UsedPct)% used)" -ForegroundColor White
    Write-Host "Last boot: $($report.BootTime)" -ForegroundColor White

    # Quick CPU throughput sample (non-destructive)
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $x = 0
        for ($i = 0; $i -lt 5000000; $i++) { $x += [math]::Sqrt($i) }
        $sw.Stop()
        $report.CPUSampleMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
        Write-Host "CPU sample (sqrt x5M): $($report.CPUSampleMs) ms" -ForegroundColor White
    } catch {}

    $file = Join-Path $Script:ReportPath "benchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json | Out-File $file -Encoding UTF8
    Write-Host ''
    Write-Host "Report saved: $file" -ForegroundColor Green
    Write-Host 'Note: reporting only; no synthetic stress applied.' -ForegroundColor Yellow
}
