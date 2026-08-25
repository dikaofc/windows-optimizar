# ================================================
# OX Defender Remover wrapper
# Invokes the standalone DefenderRemover scripts (ps1/bat/vbs).
# These live in the DefenderRemover/ folder so they can also be
# double-clicked or scheduled independently.
# =============================================================

function Invoke-DefenderRemover {
    param([switch]$Restore)

    $dir = Join-Path $Script:ScriptRoot 'DefenderRemover'
    if (-not (Test-Path $dir)) {
        Write-Host '[ERROR] DefenderRemover folder not found.' -ForegroundColor Red
        return
    }

    if ($Restore) {
        $bat = Join-Path $dir 'restore-defender.bat'
        Write-Host 'Launching Defender restore (admin required)...' -ForegroundColor Green
    } else {
        $bat = Join-Path $dir 'disable-defender.bat'
        Write-Host ''
        Write-Host '!!! This DISABLES Windows Defender (your antivirus). !!!' -ForegroundColor Red
        Write-Host 'Your PC becomes unprotected. Use the restore option to undo.' -ForegroundColor Yellow
        Write-Host ''
        $r = Read-Host 'Continue? [YES/NO]'
        if ($r -ne 'YES') { Write-Host 'Aborted.' -ForegroundColor Yellow; return }
    }

    if (Test-Path $bat) {
        try {
            Start-Process -FilePath $bat -Verb RunAs -Wait
        } catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        # Fallback to ps1
        $ps1 = Join-Path $dir $(if ($Restore) { 'restore-defender.ps1' } else { 'disable-defender.ps1' })
        if (Test-Path $ps1) {
            Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ps1`" -Force" -Verb RunAs -Wait
        }
    }
}
