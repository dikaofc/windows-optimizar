# ================================================
# OX WINDOWS OPTIMIZER - PowerShell Core Engine
# ================================================
# Version: 1.0.0
# ================================================

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$Yes,

    [Parameter()]
    [switch]$VerboseLog,

    [Parameter()]
    [switch]$Json
)

# Parse --dry-run / --yes style args for compatibility
foreach ($a in $args) {
    if ($a -eq '--dry-run') { $DryRun = $true }
    if ($a -eq '--yes') { $Yes = $true }
    if ($a -eq '--json') { $Json = $true }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$WarningPreference = 'Continue'

# Script paths (single source of truth)
$Script:ScriptRoot     = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:ModulePath     = Join-Path $Script:ScriptRoot 'modules'
$Script:ConfigPath     = Join-Path $Script:ScriptRoot 'config'
$Script:BackupPath     = Join-Path $Script:ScriptRoot 'backups'
$Script:LogPath        = Join-Path $Script:ScriptRoot 'logs'
$Script:ReportPath     = Join-Path $Script:ScriptRoot 'reports'

# Global state
$Global:OXConfig        = $null
$Global:OXOptimizations = $null
$Global:OXHardwareInfo  = $null
$Global:OXLogFile       = Join-Path $Script:LogPath 'ox-optimizer.log'
$Global:OXBackupDir     = $null
$Global:OXSystemAnalysis = $null

# Derived flags (shared across all modules)
$Global:OXDryRun       = [bool]$DryRun
$Global:OXAutoConfirm  = [bool]$Yes

# ================================================
# Logging
# ================================================
function Initialize-Logging {
    if (-not (Test-Path $Script:LogPath)) {
        New-Item -ItemType Directory -Path $Script:LogPath -Force | Out-Null
    }
    if (-not (Test-Path $Script:ReportPath)) {
        New-Item -ItemType Directory -Path $Script:ReportPath -Force | Out-Null
    }
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "[$ts] [INFO] OX Optimizer initialized" | Out-File -FilePath $Global:OXLogFile -Encoding UTF8 -Append
}

function Write-OXLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',
        [string]$Optimization = $null,
        [string]$Action = $null,
        [string]$Result = $null
    )

    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$ts] [$Level]"
    if ($Optimization) { $entry += " Optimization: $Optimization" }
    if ($Action) { $entry += " Action: $Action" }
    if ($Result) { $entry += " Result: $Result" }
    $entry += " $Message"

    try {
        $logDir = Split-Path -Parent $Global:OXLogFile
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        $entry | Out-File -FilePath $Global:OXLogFile -Encoding UTF8 -Append
    } catch {}

    if ($VerboseLog) { Write-Host $entry }
}

# ================================================
# Configuration
# ================================================
function Load-Configuration {
    $settingsFile    = Join-Path $Script:ConfigPath 'settings.json'
    $optimizationsFile = Join-Path $Script:ConfigPath 'optimizations.json'

    if (-not (Test-Path $settingsFile)) {
        Write-OXLog "Settings file not found: $settingsFile" -Level ERROR
        return $false
    }
    if (-not (Test-Path $optimizationsFile)) {
        Write-OXLog "Optimizations file not found: $optimizationsFile" -Level ERROR
        return $false
    }

    try {
        $Global:OXConfig        = Get-Content $settingsFile -Raw | ConvertFrom-Json
        $Global:OXOptimizations = Get-Content $optimizationsFile -Raw | ConvertFrom-Json
    } catch {
        Write-OXLog "Failed to parse config JSON: $($_.Exception.Message)" -Level ERROR
        return $false
    }
    return $true
}

# ================================================
# Administrator check
# ================================================
function Test-Administrator {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ================================================
# Module loader
# ================================================
# NOTE: modules MUST be dot-sourced at SCRIPT scope (not inside a function),
# otherwise their function definitions are confined to the function's scope and
# discarded on return. The list below is used both for the script-scope load
# and for the Load-Modules reporter.
$Script:OXModuleList = @(
    'Hardware.ps1', 'CPU.ps1', 'GPU.ps1', 'RAM.ps1', 'Storage.ps1',
    'Network.ps1', 'Services.ps1', 'Startup.ps1', 'Cleanup.ps1',
    'Registry.ps1', 'Restore.ps1', 'Utilities.ps1', 'Optimizations.ps1',
    'Power.ps1', 'Privacy.ps1', 'Gaming.ps1', 'Benchmark.ps1', 'Kentang.ps1', 'Defender.ps1'
)

# Dot-source every module at script scope so all functions are globally visible.
foreach ($m in $Script:OXModuleList) {
    $file = Join-Path $Script:ModulePath $m
    if (Test-Path $file) {
        try {
            . $file
            Write-OXLog "Module loaded: $m" -Level INFO
        } catch {
            Write-OXLog "Failed to load module: $m - $($_.Exception.Message)" -Level ERROR
        }
    } else {
        Write-OXLog "Module not found: $file" -Level ERROR
    }
}

function Load-Modules {
    $loaded = 0
    $failed = @()
    foreach ($m in $Script:OXModuleList) {
        $file = Join-Path $Script:ModulePath $m
        if (Test-Path $file) {
            $loaded++
        } else {
            $failed += $m
        }
    }

    if ($loaded -gt 0) {
        Write-Host "Loaded $loaded of $($Script:OXModuleList.Count) modules" -ForegroundColor Cyan
    }
    if ($failed.Count -gt 0) {
        Write-Host 'Missing/failed modules:' -ForegroundColor Red
        foreach ($f in $failed) { Write-Host "  - $f" -ForegroundColor Red }
    }
    return ($loaded -eq $Script:OXModuleList.Count)
}

# ================================================
# Banner / headers
# ================================================
function Show-Banner {
    Clear-Host
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          OX WINDOWS OPTIMIZER' -NoNewline -ForegroundColor Green
    Write-Host '                    v1.0.0' -ForegroundColor DarkGray
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Show-SystemHeader {
    $hw = $Global:OXHardwareInfo
    if (-not $hw) { return }
    Write-Host "Windows : $($hw.OS.OSName) $($hw.OS.Architecture)" -ForegroundColor White
    Write-Host "Build   : $($hw.OS.Build)" -ForegroundColor White
    Write-Host "CPU     : $($hw.CPU.Name)" -ForegroundColor White
    Write-Host "GPU     : $($hw.GPU.Name)" -ForegroundColor White
    Write-Host "RAM     : $($hw.RAM.TotalGB) GB" -ForegroundColor White
    $sys = $hw.Storage | Where-Object { $_.Drive -eq $env:SystemDrive }
    if ($sys) {
        Write-Host "Storage : $($sys.Drive) $($sys.Type)" -ForegroundColor White
    }
    Write-Host ''
}

# ================================================
# Main menu
# ================================================
function Show-MainMenu {
    Show-Banner
    Show-SystemHeader

    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '[1]  System Information' -ForegroundColor White
    Write-Host '[2]  Analyze System' -ForegroundColor White
    Write-Host '[3]  Safe Optimization' -ForegroundColor Green
    Write-Host '[4]  Gaming Optimization' -ForegroundColor Yellow
    Write-Host '[5]  Performance Optimization' -ForegroundColor Red
    Write-Host '[6]  CPU Optimization' -ForegroundColor White
    Write-Host '[7]  GPU Optimization' -ForegroundColor White
    Write-Host '[8]  RAM Optimization' -ForegroundColor White
    Write-Host '[9]  Storage Optimization' -ForegroundColor White
    Write-Host '[10] Network Optimization' -ForegroundColor White
    Write-Host '[11] Startup Manager' -ForegroundColor White
    Write-Host '[12] Services Manager' -ForegroundColor White
    Write-Host '[13] Privacy' -ForegroundColor White
    Write-Host '[14] Cleanup' -ForegroundColor White
    Write-Host '[15] Backup / Restore' -ForegroundColor White
    Write-Host '[16] Benchmark' -ForegroundColor White
    Write-Host '[17] Logs' -ForegroundColor White
    Write-Host '[18] ALL IN ONE (run all optimizations)' -ForegroundColor Magenta
    Write-Host '[19] KENTANG (brutal / weak-PC tuning)' -ForegroundColor Red
    Write-Host '[20] Defender Remover (DISABLE antivirus)' -ForegroundColor Red
    Write-Host '[0]  Exit' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    return (Read-Host 'Select')
}

# ================================================
# Main
# ================================================
function Main {
    Initialize-Logging
    Write-Host 'Initializing OX Windows Optimizer...' -ForegroundColor Cyan

    if (-not (Load-Configuration)) {
        Write-Host 'Failed to load configuration. Exiting.' -ForegroundColor Red
        exit 1
    }

    if (-not (Test-Administrator)) {
        Write-Host ''
        Write-Host '[WARNING] Running without Administrator privileges.' -ForegroundColor Yellow
        Write-Host 'Some optimizations may not be available.' -ForegroundColor Yellow
        Write-Host ''
    }

    $null = Load-Modules
    Write-Host 'Detecting hardware...' -ForegroundColor Cyan
    $Global:OXHardwareInfo = Get-HardwareInfo

    if ($Command) {
        Handle-CommandLine $Command
        return
    }

    while ($true) {
        $choice = Show-MainMenu
        switch ($choice) {
            '0' {
                Write-Host 'Exiting...' -ForegroundColor Yellow
                Write-OXLog 'Application exited by user' -Level INFO
                exit 0
            }
            '1'  { Show-SystemInformation }
            '2'  { $Global:OXSystemAnalysis = Analyze-System }
            '3'  { Invoke-SafeOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '4'  { Invoke-GamingOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '5'  { Invoke-PerformanceOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '6'  { Invoke-CPUOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '7'  { Invoke-GPUOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '8'  { Invoke-RAMOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '9'  { Invoke-StorageOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '10' { Invoke-NetworkOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '11' { Show-StartupManager }
            '12' { Show-ServicesManager }
            '13' { Invoke-PrivacyOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '14' { Invoke-Cleanup -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '15' { Show-BackupRestoreMenu }
            '16' { Invoke-Benchmark }
            '17' { Show-Logs }
            '18' { Invoke-AllInOne -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '19' { Invoke-KentangOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
            '20' { Invoke-DefenderRemover }
            default {
                Write-Host 'Invalid selection. Please try again.' -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }

        if ($choice -ne '0') {
            Write-Host ''
            Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    }
}

# ================================================
# Command-line handler
# ================================================
function Handle-CommandLine {
    param([string]$Command)
    Write-OXLog "Command line mode: $Command" -Level INFO

    $isAdmin = Test-Administrator
    if (-not $isAdmin -and $Command -notin @('scan', 'analyze', 'logs', 'benchmark')) {
        Write-Host '[WARNING] Not running as Administrator; some actions will be skipped.' -ForegroundColor Yellow
    }

    switch ($Command.ToLower()) {
        'scan' {
            $Global:OXSystemAnalysis = Analyze-System
            if ($Json) { $Global:OXSystemAnalysis | ConvertTo-Json -Depth 10 }
        }
        'analyze' {
            $Global:OXSystemAnalysis = Analyze-System
            if ($Json) { $Global:OXSystemAnalysis | ConvertTo-Json -Depth 10 }
        }
        'safe'        { Invoke-SafeOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'gaming'      { Invoke-GamingOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'performance' { Invoke-PerformanceOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'cpu'         { Invoke-CPUOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'gpu'         { Invoke-GPUOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'ram'         { Invoke-RAMOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'storage'     { Invoke-StorageOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'network'     { Invoke-NetworkOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'privacy'     { Invoke-PrivacyOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'startup'     { Show-StartupManager }
        'services'    { Show-ServicesManager }
        'cleanup'     { Invoke-Cleanup -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'backup'      { Invoke-Backup }
        'restore'     { Invoke-Restore-Last }
        'benchmark'   { Invoke-Benchmark }
        'all'         { Invoke-AllInOne -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'kentang'     { Invoke-KentangOptimization -DryRun:$Global:OXDryRun -AutoConfirm:$Global:OXAutoConfirm }
        'defender'    { Invoke-DefenderRemover }
        'defender-restore' { Invoke-DefenderRemover -Restore }
        'logs'        { Show-Logs }
        default {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Write-Host 'Available: scan, analyze, safe, gaming, performance, cpu, gpu, ram, storage, network, privacy, startup, services, cleanup, backup, restore, benchmark, all, kentang, logs' -ForegroundColor Yellow
            exit 1
        }
    }
}

# ================================================
# ALL IN ONE - run every optimization except benchmark
# ================================================
function Invoke-AllInOne {
    param([switch]$DryRun, [switch]$AutoConfirm)

    $dr = [bool]$DryRun

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Magenta
    Write-Host '          ALL IN ONE OPTIMIZATION' -ForegroundColor Magenta
    Write-Host '==================================================' -ForegroundColor Magenta
    Write-Host ''

    if ($dr) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        Write-Host 'The list below previews every change each optimizer would apply.' -ForegroundColor Yellow
        Write-Host ''
    } else {
        $continue = $true
        if (-not $AutoConfirm) {
            $r = Read-Host 'Run ALL optimizations (excluding benchmark)? [Y/N]'
            $continue = $r -match '^[Yy]$'
        }
        if (-not $continue) { return }

        # One backup up front covers all subsequent changes.
        Invoke-Backup 2>$null | Out-Null
    }

    $confirm = -not $dr   # real mode applies silently; dry-run never applies
    $steps = @(
        { Invoke-SafeOptimization         -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-GamingOptimization       -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-PerformanceOptimization  -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-CPUOptimization          -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-GPUOptimization          -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-RAMOptimization          -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-StorageOptimization      -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-NetworkOptimization      -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-PrivacyOptimization      -DryRun:$dr -AutoConfirm:$confirm },
        { Invoke-Cleanup                  -DryRun:$dr -AutoConfirm:$confirm }
    )

    # Startup / Services are interactive selectors - list state without blocking.
    $steps += {
        Write-Host '--- Startup programs (current state) ---' -ForegroundColor Cyan
        $sp = Get-StartupPrograms
        if ($sp.Count -eq 0) { Write-Host '  None found.' -ForegroundColor Gray }
        foreach ($p in $sp) {
            Write-Host "  [$($p.Status)] $($p.Name)" -ForegroundColor White
        }
        Write-Host ''
        Write-Host '--- Services (recommended optimizations) ---' -ForegroundColor Cyan
        $sv = Get-OptimizableServices
        foreach ($s in $sv) {
            Write-Host "  [$($s.Risk)] $($s.Name) -> $($s.Recommendation)" -ForegroundColor White
        }
    }

    foreach ($step in $steps) {
        try {
            & $step
            Write-Host ''
        } catch {
            Write-OXLog "ALL IN ONE step failed: $($_.Exception.Message)" -Level ERROR
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host '==================================================' -ForegroundColor Magenta
    if ($dr) {
        Write-Host 'DRY RUN complete. No changes made (benchmark excluded).' -ForegroundColor Yellow
    } else {
        Write-Host 'ALL IN ONE completed (benchmark excluded).' -ForegroundColor Green
        Write-Host 'A restart may be required for some changes to take effect.' -ForegroundColor Yellow
    }
    Write-Host '==================================================' -ForegroundColor Magenta
}

# ================================================
# Run
# ================================================
Main
