# ================================================
# OX Gaming Module
# ================================================

function Enable-GameMode {
    param([switch]$DryRun)
    Write-OXLog 'Enabling Game Mode' -Level INFO -Action 'Enable-GameMode'
    Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1 -Type DWord -DryRun:$DryRun
    Set-RegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Config' -Value 2 -Type DWord -DryRun:$DryRun
    Set-RegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehavior' -Value 2 -Type DWord -DryRun:$DryRun
    Write-Host '  [OK] Game Mode enabled.' -ForegroundColor Green
}

function Check-GameMode {
    $v = (Get-ItemProperty 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -ErrorAction SilentlyContinue).AutoGameModeEnabled
    return ($v -eq 1)
}

function Disable-GameMode {
    param([switch]$DryRun)
    Write-OXLog 'Disabling Game Mode' -Level INFO -Action 'Disable-GameMode'
    Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 0 -Type DWord -DryRun:$DryRun
    Write-Host '  [OK] Game Mode disabled.' -ForegroundColor Green
}
