# ================================================
# OX Benchmark Module (wrapper)
# ================================================
# The actual reporting implementation lives in Utilities.ps1
# (Invoke-Benchmark). This file keeps the module list consistent
# and lets a future standalone benchmark expand here.

function Invoke-BenchmarkModule {
    Write-Host '[INFO] See Utilities.ps1: Invoke-Benchmark for reporting.' -ForegroundColor Yellow
    Invoke-Benchmark
}
