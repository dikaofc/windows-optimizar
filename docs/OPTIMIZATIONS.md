# OX Windows Optimizer - Optimizations Reference

## Optimization ID System

Each optimization has a unique ID following the pattern: `OX-CATEGORY-NUMBER`

| Prefix | Category |
|--------|----------|
| OX-CLEAN | Cleanup |
| OX-NET | Network |
| OX-GAME | Gaming |
| OX-POWER | Power |
| OX-CPU | CPU |
| OX-GPU | GPU |
| OX-RAM | RAM |
| OX-STOR | Storage |
| OX-START | Startup |
| OX-SVC | Services |
| OX-PRIV | Privacy |
| OX-REG | Registry |

## Risk Levels

| Level | Description |
|-------|-------------|
| SAFE | No system behavior changes. Read-only or reversible file cleanup. |
| LOW | Minor configuration changes that are easily reversible. |
| MEDIUM | Configuration changes that may affect system behavior. |
| ADVANCED | Changes requiring careful review. Expert users only. |

## Cleanup Optimizations

### OX-CLEAN-001: Temporary File Cleanup (User)
- **Risk:** SAFE
- **Description:** Removes temporary files from the user temp directory
- **What it does:** Cleans files in `%TEMP%`
- **Rollback:** N/A (files are regenerated as needed)

### OX-CLEAN-002: Temporary File Cleanup (System)
- **Risk:** SAFE
- **Description:** Removes temporary files from the Windows temp directory
- **What it does:** Cleans files in `%SYSTEMROOT%\Temp`
- **Rollback:** N/A (files are regenerated as needed)

### OX-CLEAN-003: Recycle Bin Cleanup
- **Risk:** SAFE
- **Description:** Empties the Recycle Bin
- **What it does:** Clears all files from Recycle Bin
- **Rollback:** N/A (files cannot be recovered after emptying)

### OX-CLEAN-004: Windows Update Cache Cleanup
- **Risk:** SAFE
- **Description:** Cleans downloaded Windows Update cache files
- **What it does:** Cleans `%SYSTEMROOT%\SoftwareDistribution\Download`
- **Rollback:** N/A (cache is regenerated on next update check)

## Network Optimizations

### OX-NET-001: DNS Cache Flush
- **Risk:** SAFE
- **Description:** Flushes DNS resolver cache
- **What it does:** Runs `Clear-DnsClientCache`
- **Rollback:** N/A (cache rebuilds automatically)

### OX-NET-002: Network Adapter Information
- **Risk:** SAFE
- **Description:** Displays network adapter configuration
- **What it does:** Read-only display of network info

### OX-NET-003: TCP Configuration Analysis
- **Risk:** SAFE
- **Description:** Analyzes TCP/IP stack configuration
- **What it does:** Read-only display of TCP settings

## Gaming Optimizations

### OX-GAME-001: Enable Game Mode
- **Risk:** LOW
- **Description:** Enables Windows Game Mode
- **Registry:** `HKCU\Software\Microsoft\GameBar`
- **Rollback:** Set `AllowAutoGameMode` to 0

### OX-GAME-002: Disable Game DVR
- **Risk:** LOW
- **Description:** Disables Xbox Game DVR recording
- **Registry:** `HKCU\System\GameConfigStore`, `HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR`
- **Rollback:** Set values back to 1

### OX-GAME-003: Disable Fullscreen Optimizations
- **Risk:** LOW
- **Description:** Disables Windows fullscreen optimizations
- **Registry:** `HKCU\System\GameConfigStore`
- **Rollback:** Remove or reset `GameDVR_FSEBehaviorMode` and related values

## Power Optimizations

### OX-POWER-001: High Performance Power Plan
- **Risk:** LOW
- **Description:** Sets power plan to High Performance (desktops only)
- **What it does:** Activates Ultimate Performance or High Performance power plan
- **Rollback:** Set power plan back to Balanced

### OX-POWER-002: Disable USB Selective Suspend
- **Risk:** LOW
- **Description:** Disables USB selective suspend
- **What it does:** Modifies power plan USB settings
- **Rollback:** Re-enable via powercfg

## CPU Optimizations

### OX-CPU-001: CPU Core Parking Analysis
- **Risk:** SAFE
- **Description:** Analyzes CPU core parking settings
- **What it does:** Read-only analysis

### OX-CPU-002: CPU Power Management Analysis
- **Risk:** SAFE
- **Description:** Analyzes CPU power management
- **What it does:** Read-only analysis

### OX-CPU-003: Processor Scheduling
- **Risk:** LOW
- **Description:** Optimizes processor scheduling
- **Registry:** `HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl`
- **Rollback:** Set `Win32PrioritySeparation` back to original value

## GPU Optimizations

### OX-GPU-001: GPU Information and Recommendations
- **Risk:** SAFE
- **Description:** Displays GPU info and driver recommendations
- **What it does:** Read-only display

### OX-GPU-002: Hardware-Accelerated GPU Scheduling
- **Risk:** SAFE
- **Description:** Checks HAGS status
- **What it does:** Read-only check

## RAM Optimizations

### OX-RAM-001: Memory Usage Analysis
- **Risk:** SAFE
- **Description:** Analyzes memory usage and top processes
- **What it does:** Read-only analysis

### OX-RAM-002: Pagefile Analysis
- **Risk:** SAFE
- **Description:** Analyzes pagefile configuration
- **What it does:** Read-only analysis

## Storage Optimizations

### OX-STOR-001: Storage Health Check
- **Risk:** SAFE
- **Description:** Checks storage health via S.M.A.R.T.
- **What it does:** Read-only health check

### OX-STOR-002: TRIM Status Check
- **Risk:** SAFE
- **Description:** Verifies TRIM is enabled for SSD/NVMe
- **What it does:** Read-only check

### OX-STOR-003: Storage Analysis
- **Risk:** SAFE
- **Description:** Analyzes storage usage across all drives
- **What it does:** Read-only analysis

## Privacy Optimizations

### OX-PRIV-001: Privacy Settings Review
- **Risk:** SAFE
- **Description:** Reviews Windows privacy settings
- **What it does:** Read-only review

### OX-PRIV-002: Telemetry Review
- **Risk:** SAFE
- **Description:** Reviews telemetry settings
- **What it does:** Read-only review

### OX-PRIV-003: Disable Activity History
- **Risk:** LOW
- **Description:** Disables Windows Activity History tracking
- **Registry:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`
- **Rollback:** Remove or set values to 1

## Registry Operations

### OX-REG-001: Registry Backup
- **Risk:** SAFE
- **Description:** Creates backup of important registry keys
- **What it does:** Exports registry keys to backup directory
