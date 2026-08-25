# ================================================
# OX GPU Optimization Module  (REAL, APPLIED tweaks)
# ================================================

function Invoke-GPUOptimization {
    param([switch]$DryRun, [switch]$AutoConfirm)

    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '          GPU OPTIMIZATION' -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host ''

    $gpuInfo = Get-GPUInfo
    $name = if ($gpuInfo -is [array]) { $gpuInfo[0].Name } else { $gpuInfo.Name }
    $manu = if ($gpuInfo -is [array]) { $gpuInfo[0].Manufacturer } else { $gpuInfo.Manufacturer }
    $vendor = Get-GPUVendor $manu

    Write-Host "Detected GPU: $name" -ForegroundColor White
    Write-Host "Vendor: $vendor" -ForegroundColor White
    Write-Host ''

    # Real, scriptable tweaks (all reversible via backup/restore or documented undo).
    $tweaks = @(
        @{ ID = 'OX-GPU-001'; Desc = 'Enable hardware acceleration'; Path = 'HKCU:\Software\Microsoft\Avalon.Graphics'; Name = 'DisableHWAcceleration'; Value = 0; Type = 'DWord'; Risk = 'LOW' },
        @{ ID = 'OX-GPU-002'; Desc = 'Disable Hardware GPU Scheduling (helps weak/old GPUs)'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name = 'HwSchMode'; Value = 1; Type = 'DWord'; Risk = 'LOW' }
    )
    if ($vendor -eq 'AMD') {
        $tweaks += @{ ID = 'OX-GPU-003'; Desc = 'Disable ULPS (keeps discrete GPU awake on dual-graphics)'; Risk = 'MEDIUM'; ULPS = $true }
    }

    foreach ($t in $tweaks) {
        $c = Get-RiskColor $t.Risk
        Write-Host "[$($t.ID)] $($t.Desc)" -ForegroundColor White
        Write-Host "  Risk: " -NoNewline; Write-Host $t.Risk -ForegroundColor $c
    }
    # Informational only (no fake registry that doesn't exist).
    Write-Host "[OX-GPU-9xx] Driver age check (info only)" -ForegroundColor White
    if ($vendor -eq 'NVIDIA') {
        Write-Host "  [INFO] For max perf also set NVIDIA Control Panel > Manage 3D Settings > Power Management = Prefer Maximum Performance (no CLI equivalent)." -ForegroundColor DarkGray
    }
    Write-Host ''

    if ($DryRun) {
        Write-Host 'DRY RUN MODE - No changes will be made' -ForegroundColor Yellow
        return
    }

    $continue = $true
    if (-not $AutoConfirm) {
        $r = Read-Host 'Apply GPU optimizations? [Y/N]'
        $continue = $r -match '^[Yy]$'
    }
    if (-not $continue) { return }

    foreach ($t in $tweaks) {
        try {
            Write-OXLog "Applying GPU $($t.ID)" -Level INFO -Optimization $t.ID -Action 'Apply'
            if ($t.ULPS) {
                # Enumerate display-class adapters and disable ULPS (real, reversible to 1).
                $cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
                Get-ChildItem $cls -ErrorAction SilentlyContinue | ForEach-Object {
                    $p = $_.PSPath
                    if (Test-Path "$p\EnableULPS") {
                        Set-RegistryValue -Path $p -Name 'EnableULPS' -Value 0 -Type 'DWord' -DryRun:$false
                    }
                }
                Write-Host '  [OK] ULPS disabled on display adapters.' -ForegroundColor Green
            } else {
                Set-RegistryValue -Path $t.Path -Name $t.Name -Value $t.Value -Type $t.Type -DryRun:$false
            }
            Write-OXLog "Applied GPU $($t.ID)" -Level SUCCESS -Optimization $t.ID -Action 'Apply' -Result 'SUCCESS'
        } catch {
            Write-OXLog "Failed GPU $($t.ID) - $($_.Exception.Message)" -Level ERROR
            Write-Host "  [ERROR] $($t.ID): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Driver age info (no change).
    $dd = if ($gpuInfo -is [array]) { $gpuInfo[0].DriverDate } else { $gpuInfo.DriverDate }
    if ($dd) {
        $days = ((Get-Date) - $dd).Days
        if ($days -gt 365) { Write-Host "  [WARNING] Driver is $days days old. Update it." -ForegroundColor Yellow }
        else { Write-Host "  [OK] Driver $days days old." -ForegroundColor Green }
    }

    Write-Host ''
    Write-Host 'GPU optimization completed!' -ForegroundColor Green
}
