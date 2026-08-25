# ================================================
# OX Cleanup Module
# ================================================

function Invoke-Cleanup {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          SYSTEM CLEANUP' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        Write-Host ''
    }

    $continue = $true
    if (-not $DryRun -and -not $AutoConfirm) {
        $r = Read-Host 'Run system cleanup? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }

    if ($continue) {
        $temp = Clean-TempFiles -DryRun:$DryRun
        $bin  = Clean-RecycleBin -DryRun:$DryRun
        $wu   = Clean-WindowsUpdateCache -DryRun:$DryRun

        Write-Host ''
        Write-Host "Cleanup complete: $temp MB temp, $bin MB recycle bin, $wu MB update cache." -ForegroundColor Green
    }
}

function Flush-DNSCache {
    param([switch]$DryRun)
    if (-not $DryRun) {
        try { Clear-DnsClientCache } catch {}
    }
    Write-Host '  [OK] DNS cache flushed.' -ForegroundColor Green
}

function Clean-TempFiles {
    param([switch]$DryRun)
    $folders = @($env:TEMP, "$env:SystemRoot\Temp")
    $total = 0
    foreach ($f in $folders) {
        if (Test-Path $f) {
            Get-ChildItem $f -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $total += $_.Length
                    if (-not $DryRun) { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }
                } catch {}
            }
        }
    }
    return [math]::Round($total / 1MB, 2)
}

function Clean-RecycleBin {
    param([switch]$DryRun)
    $total = 0
    try {
        $shell = New-Object -ComObject Shell.Application
        $bin = $shell.NameSpace(10)
        $bin.Items() | ForEach-Object { try { $total += $_.Size } catch {} }
        if (-not $DryRun) { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
    } catch {}
    return [math]::Round($total / 1MB, 2)
}

function Clean-WindowsUpdateCache {
    param([switch]$DryRun)
    $path = "$env:SystemRoot\SoftwareDistribution\Download"
    $total = 0
    if (Test-Path $path) {
        Get-ChildItem $path -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $total += $_.Length
                if (-not $DryRun) { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }
            } catch {}
        }
    }
    return [math]::Round($total / 1MB, 2)
}
