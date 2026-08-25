# OX Windows Optimizer - Rollback Guide

## How Rollback Works

OX Windows Optimizer creates backups before every optimization. The rollback system allows you to restore your system to its previous state.

## Backup Locations

```
backups/
    2026-08-25_12-00-00/
        manifest.json        # Backup metadata
        registry/            # Registry key exports (.reg files)
        services/            # Service state snapshots
        power/               # Power configuration snapshots
```

## Restore Methods

### Method 1: Using the Main Tool

1. Run `OX-Optimizer.bat`
2. Select option `[15] Backup / Restore`
3. Choose one of:
   - `[1] Create Backup` — Create a new backup
   - `[2] List Backups` — View available backups
   - `[3] Restore Last Changes` — Restore from the most recent backup

### Method 2: Restore Last Registry Changes

The tool tracks individual registry changes in `backups/last_registry_changes.json`. To restore:

1. Run `OX-Optimizer.bat`
2. Select option `[15] Backup / Restore`
3. Select `[3] Restore Last Changes`

### Method 3: Restore All from Latest Backup

1. Run `OX-Optimizer.bat`
2. Select option `[15] Backup / Restore`
3. Select `[2] List Backups` to see available backups
4. Use the restore function to apply the latest backup

### Method 4: Standalone Restore (No Tool Required)

1. Navigate to `uninstall/`
2. Run `Restore-All.bat` as Administrator
3. Follow the prompts

### Method 5: Manual Registry Import

1. Navigate to `backups/` and find the backup directory
2. Open the `registry/` subfolder
3. Double-click any `.reg` file to import it
4. Restart your computer

## What Gets Backed Up

| Component | Method | Location |
|-----------|--------|----------|
| Registry Keys | `.reg` export | `backups/<date>/registry/` |
| Power Config | `powercfg /query` output | `backups/<date>/power/` |
| Service States | CSV export | `backups/<date>/services/` |
| System Restore Point | Windows native | System Restore |

## System Restore Point

If enabled in settings, the tool creates a Windows System Restore Point before each optimization. This can be used as a last resort:

1. Press `Win + R`, type `rstrui.exe`, press Enter
2. Select a restore point from before the optimization
3. Follow the wizard

## Important Notes

- Backups are stored locally on your system
- Registry backups capture the exact state of each key before modification
- Service states are logged but not automatically restored (to prevent system instability)
- Always restart after a full restore for changes to take effect
- If the tool cannot create a restore point, it will warn you before proceeding with high-risk operations

## Emergency Recovery

If the system becomes unstable:

1. Boot into Safe Mode (hold Shift while clicking Restart)
2. Run `Restore-All.bat` from Safe Mode, or
3. Use Windows System Restore from Safe Mode
4. As a last resort, use Windows Reset (Settings > Update & Security > Recovery)
