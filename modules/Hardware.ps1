# ================================================
# OX Hardware Detection Module
# ================================================

function Get-HardwareInfo {
    $hardwareInfo = @{
        OS       = Get-OSInfo
        CPU      = Get-CPUInfo
        GPU      = Get-GPUInfo
        RAM      = Get-RAMInfo
        Storage  = Get-StorageInfo
        Network  = Get-NetworkAdapterInfo
    }
    return $hardwareInfo
}

function Get-OSInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    return @{
        OSName        = $os.Caption
        Version       = $os.Version
        Build         = $os.BuildNumber
        Architecture  = $os.OSArchitecture
        Manufacturer  = $cs.Manufacturer
        Model         = $cs.Model
        LastBoot      = $os.LastBootUpTime
        InstallDate   = $os.InstallDate
    }
}

function Get-CPUInfo {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    return @{
        Name                 = $cpu.Name
        Manufacturer         = $cpu.Manufacturer
        Cores                = $cpu.NumberOfCores
        LogicalProcessors    = $cpu.NumberOfLogicalProcessors
        MaxClockSpeed        = $cpu.MaxClockSpeed
        CurrentClockSpeed    = $cpu.CurrentClockSpeed
        LoadPercentage       = $cpu.LoadPercentage
        L2CacheSize          = $cpu.L2CacheSize
        L3CacheSize          = $cpu.L3CacheSize
        VirtualizationEnabled = $cpu.VirtualizationFirmwareEnabled
        Architecture         = $cpu.Architecture
        Family               = $cpu.Family
        Stepping             = $cpu.Stepping
    }
}

function Get-GPUInfo {
    $gpus = Get-CimInstance Win32_VideoController | Where-Object { $_.Status -eq 'OK' -or $_.PNPDeviceID }
    if (-not $gpus) {
        return @{
            Name          = 'No GPU detected'
            Manufacturer  = 'Unknown'
            DriverVersion = 'N/A'
            DriverDate    = $null
            AdapterRAM    = 0
            Status        = 'N/A'
        }
    }
    $list = @()
    foreach ($gpu in $gpus) {
        $list += @{
            Name                = $gpu.Name
            Manufacturer        = $gpu.AdapterCompatibility
            DriverVersion       = $gpu.DriverVersion
            DriverDate          = $gpu.DriverDate
            VideoModeDescription = $gpu.VideoModeDescription
            AdapterRAM          = $gpu.AdapterRAM
            CurrentResolution   = "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
            CurrentRefreshRate  = $gpu.CurrentRefreshRate
            Status              = $gpu.Status
        }
    }
    if ($list.Count -eq 1) { return $list[0] }
    return $list
}

function Get-RAMInfo {
    $ram = Get-CimInstance Win32_PhysicalMemory
    $cs  = Get-CimInstance Win32_ComputerSystem
    $os  = Get-CimInstance Win32_OperatingSystem

    $totalBytes = ($ram | Measure-Object -Property Capacity -Sum).Sum
    $totalGB = [math]::Round($totalBytes / 1GB, 2)
    $freeMB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedGB  = [math]::Round(($totalGB - $freeMB), 2)

    return @{
        TotalGB      = $totalGB
        TotalBytes   = $totalBytes
        Speed        = ($ram | Select-Object -First 1).Speed
        Manufacturer = ($ram | Select-Object -First 1).Manufacturer
        PartNumber   = ($ram | Select-Object -First 1).PartNumber
        SlotsUsed    = $ram.Count
        FormFactor   = ($ram | Select-Object -First 1).FormFactor
        AvailableGB  = $freeMB
        UsedGB       = $usedGB
        UsagePercent = [math]::Round((($totalGB - $freeMB) / $totalGB) * 100, 1)
    }
}

function Get-StorageInfo {
    $drives     = Get-CimInstance Win32_DiskDrive
    $partitions = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $list = @()

    foreach ($drive in $drives) {
        $list += @{
            Model         = $drive.Model
            Manufacturer  = $drive.Manufacturer
            SerialNumber  = $drive.SerialNumber
            SizeGB        = [math]::Round($drive.Size / 1GB, 2)
            InterfaceType = $drive.InterfaceType
            MediaType     = $drive.MediaType
            Partitions    = $drive.Partitions
            Drive         = $null
            Type          = Get-StorageType $drive
        }
    }

    foreach ($p in $partitions) {
        $type = $null
        $driveLetter = $p.DeviceID.TrimEnd(':')
        try {
            $part = Get-Partition -DriveLetter $driveLetter -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($part) {
                $disk = Get-Disk -Number $part.DiskNumber -ErrorAction SilentlyContinue
                if ($disk -and $disk.BusType) {
                    # BusType is the most reliable indicator under StrictMode
                    switch ($disk.BusType) {
                        'NVMe'  { $type = 'NVMe SSD' }
                        'SCSI'  { $type = 'SSD' }
                        'ATA'   { $type = 'HDD' }
                        'SATA'  { $type = 'HDD' }
                        default { $type = $disk.BusType }
                    }
                }
            }
        } catch {}
        if (-not $type) { $type = 'Unknown' }
        $list += @{
            Model         = $null
            Manufacturer  = $null
            SerialNumber  = $null
            SizeGB        = [math]::Round($p.Size / 1GB, 2)
            FreeSpaceGB   = [math]::Round($p.FreeSpace / 1GB, 2)
            UsedSpaceGB   = [math]::Round(($p.Size - $p.FreeSpace) / 1GB, 2)
            FileSystem    = $p.FileSystem
            Drive         = $p.DeviceID
            VolumeName    = $p.VolumeName
            Compressed    = $p.Compressed
            Type          = $type
        }
    }
    return $list
}

function Get-StorageType {
    param($Drive)
    $type = 'Unknown'
    if ($Drive.MediaType -eq 'Fixed hard disk media') { $type = 'HDD' }
    elseif ($Drive.MediaType -eq 'External hard disk media') { $type = 'External HDD' }
    elseif ($Drive.InterfaceType -eq 'SCSI') { $type = 'SSD' }
    elseif ($Drive.InterfaceType -eq 'IDE') { $type = 'HDD' }
    elseif ($Drive.InterfaceType -eq 'USB') { $type = 'USB Storage' }
    elseif ($Drive.Model -match 'SSD|NVMe|M.2') { $type = 'SSD' }

    if ($Drive.InterfaceType -eq 'SCSI' -and $Drive.Model -match 'NVMe') { $type = 'NVMe SSD' }
    return $type
}

function Get-NetworkAdapterInfo {
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
    $list = @()
    foreach ($a in $adapters) {
        $list += @{
            Name             = $a.Name
            InterfaceDescription = $a.InterfaceDescription
            MacAddress       = $a.MacAddress
            LinkSpeed        = $a.LinkSpeed
            Status           = $a.Status
            DriverVersion    = $a.DriverVersion
            DriverDate       = $a.DriverDate
        }
    }
    return $list
}

function Get-CPUVendor {
    param([string]$Manufacturer)
    if ($Manufacturer -match 'Intel') { return 'Intel' }
    elseif ($Manufacturer -match 'AMD') { return 'AMD' }
    return 'Unknown'
}

function Get-GPUVendor {
    param([string]$Manufacturer)
    if ($Manufacturer -match 'NVIDIA') { return 'NVIDIA' }
    elseif ($Manufacturer -match 'AMD|ATI') { return 'AMD' }
    elseif ($Manufacturer -match 'Intel') { return 'Intel' }
    return 'Unknown'
}
