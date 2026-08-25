# OX Windows Optimizer

A modular, portable Windows 10 optimization toolkit built entirely with native Windows scripting.

## Overview

OX Windows Optimizer detects your hardware, analyzes your system, and provides safe, reversible optimizations. It uses only `.bat`, `.cmd`, `.ps1`, `.json`, and `.md` files — no compiled code, no third-party dependencies.

**Target:** Windows 10 64-bit — Universal Hardware (Intel, AMD, NVIDIA, HDD, SSD, NVMe, Desktop, Laptop)

## Features

- **Hardware Detection** — CPU, GPU, RAM, Storage, Motherboard, BIOS via native WMI/CIM
- **System Analysis** — Comprehensive system health report
- **Safe Optimizations** — Low-risk maintenance (temp cleanup, DNS flush, TRIM verification)
- **Gaming Profile** — Game Mode, Game DVR, fullscreen optimizations
- **Performance Profile** — High-performance power plan, startup optimization
- **CPU/GPU/RAM/Storage Modules** — Hardware-specific analysis and recommendations
- **Network Module** — DNS flush, TCP analysis, adapter information
- **Services Manager** — Categorizes services by risk level
- **Startup Manager** — Lists and analyzes startup programs
- **Privacy Review** — Reviews telemetry and privacy settings
- **Backup & Restore** — Registry backup, restore points, rollback system
- **Benchmark** — CPU, RAM, disk, network performance metrics
- **Dry Run Mode** — Preview changes before applying
- **CLI Support** — Command-line arguments for automation
- **Logging** — All operations logged with timestamps

## Requirements

- Windows 10 64-bit
- PowerShell 5.1+
- Administrator privileges (recommended for full functionality)

## Quick Start

### Interactive Mode
```cmd
OX-Optimizer.bat
```

### Command Line Mode
```cmd
OX-Optimizer.bat analyze
OX-Optimizer.bat safe
OX-Optimizer.bat gaming
OX-Optimizer.bat performance
```

### With Flags
```cmd
OX-Optimizer.bat safe --dry-run
OX-Optimizer.bat gaming --yes
OX-Optimizer.bat analyze --verbose
```

## Menu Options

| Option | Description |
|--------|-------------|
| 1 | System Information |
| 2 | Analyze System |
| 3 | Safe Optimization |
| 4 | Gaming Optimization |
| 5 | Performance Optimization |
| 6 | CPU Optimization |
| 7 | GPU Optimization |
| 8 | RAM Optimization |
| 9 | Storage Optimization |
| 10 | Network Optimization |
| 11 | Startup Manager |
| 12 | Services Manager |
| 13 | Privacy |
| 14 | Cleanup |
| 15 | Backup / Restore |
| 16 | Benchmark |
| 17 | Logs |
| 0 | Exit |

## CLI Commands

| Command | Description |
|---------|-------------|
| `info` | Show system information |
| `analyze` | Run full system analysis |
| `safe` | Apply safe optimizations |
| `gaming` | Apply gaming optimizations |
| `performance` | Apply performance optimizations |
| `cpu` | CPU analysis |
| `gpu` | GPU analysis |
| `ram` | RAM analysis |
| `storage` | Storage analysis |
| `network` | Network analysis |
| `startup` | Startup program analysis |
| `services` | Service analysis |
| `privacy` | Privacy settings review |
| `cleanup` | Run system cleanup |
| `backup` | Backup / Restore menu |
| `restore` | Restore menu |
| `benchmark` | Run benchmark |
| `logs` | View logs |

## CLI Flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview changes without applying |
| `--yes` | Skip confirmation prompts |
| `--verbose` | Show detailed logging output |
| `--json` | Output in JSON format |

## Presets

| Preset | Description |
|--------|-------------|
| Safe | Lowest-risk maintenance only |
| Gaming | Gaming-oriented optimizations |
| Performance | Maximum performance (desktops) |
| Balanced | Balanced optimizations |
| Laptop | Battery-friendly optimizations |

## Project Structure

```
OX-Windows-Optimizer/
├── OX-Optimizer.bat          # Main launcher
├── OX-Optimizer.ps1          # Main engine
├── config/
│   ├── settings.json         # Global settings
│   └── optimizations.json    # Optimization metadata
├── modules/
│   ├── Hardware.ps1          # Hardware detection
│   ├── CPU.ps1               # CPU optimization
│   ├── GPU.ps1               # GPU optimization
│   ├── RAM.ps1               # RAM optimization
│   ├── Storage.ps1           # Storage optimization
│   ├── Network.ps1           # Network optimization
│   ├── Services.ps1          # Services manager
│   ├── Startup.ps1           # Startup manager
│   ├── Privacy.ps1           # Privacy settings
│   ├── Gaming.ps1            # Gaming optimization
│   ├── Power.ps1             # Power optimization
│   ├── Cleanup.ps1           # System cleanup
│   ├── Registry.ps1          # Registry management
│   └── Restore.ps1           # Restore/rollback
├── presets/                   # Optimization presets
├── backups/                   # Backup storage
├── logs/                      # Operation logs
├── reports/                   # Benchmark reports
├── docs/                      # Documentation
└── uninstall/
    └── Restore-All.bat       # Standalone restore
```

## Safety

- All changes are backed up before applying
- System Restore Point created when possible
- Dry Run mode available for all optimizations
- Critical services are never disabled
- No system files are modified
- All optimizations are reversible

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.

## License

Free to use and modify.
