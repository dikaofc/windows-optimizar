# OX Windows Optimizer - Troubleshooting

## Common Issues

### "Administrator privileges required"

**Symptom:** The tool prompts for administrator privileges.

**Solution:**
- Right-click `OX-Optimizer.bat` and select "Run as administrator"
- If UAC is blocking the tool, click "Yes" when prompted
- Some features work without admin, but optimization requires elevated privileges

### "PowerShell execution policy" error

**Symptom:** Scripts fail to run due to execution policy restrictions.

**Solution:**
The tool uses `-ExecutionPolicy Bypass` which should work on most systems. If it still fails:
```cmd
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
```

### Module loading fails

**Symptom:** "Failed to load module" messages in the log.

**Solution:**
1. Ensure all files in `modules/` directory are present
2. Check that `.ps1` files are not blocked by Windows (right-click > Properties > Unblock)
3. Run `powershell -Command "Get-ExecutionPolicy"` to verify policy

### Backup creation fails

**Symptom:** "Could not create restore point" warning.

**Solution:**
- System Restore must be enabled on the system drive
- Enable it: Right-click "This PC" > Properties > System Protection > Configure > Turn on
- If System Restore is managed by IT policy, the tool will skip this step

### Cleanup frees no space

**Symptom:** Cleanup reports 0 MB freed.

**Solution:**
- This is normal if temp files were recently cleaned
- Try running Windows Disk Cleanup for additional cleaning
- Check if antivirus is locking temp files

### "Access denied" on service operations

**Symptom:** Cannot analyze or modify services.

**Solution:**
- Run as Administrator
- Some services are protected by Windows and cannot be modified
- The tool categorizes these as "DO NOT TOUCH"

### Menu doesn't display correctly

**Symptom:** Menu looks garbled or colors are wrong.

**Solution:**
- Ensure your terminal supports ANSI colors
- Use Windows Terminal or ConEmu for best results
- If running in CMD, ensure the window is wide enough (80+ columns)

### Benchmark shows -1 latency

**Symptom:** Network benchmark shows -1 for latency.

**Solution:**
- No internet connection detected
- Check your network adapter status
- The tool uses 8.8.8.8 for ping tests

### Dry run doesn't seem to work

**Symptom:** Changes are applied even with `--dry-run`.

**Solution:**
- Ensure `--dry-run` is passed correctly
- Check the logs in `logs/ox-optimizer.log` for dry run confirmations
- Dry run messages appear in magenta/purple

## Log File

All operations are logged to `logs/ox-optimizer.log`. Check this file for detailed information about what the tool did.

Log format:
```
[2026-08-25 12:00:00] [INFO] Optimization: OX-GAME-001 Action: Apply
[2026-08-25 12:00:01] [SUCCESS] Optimization: OX-GAME-001 Result: SUCCESS
```

## Getting Help

1. Check the logs directory for error details
2. Review this troubleshooting guide
3. Try running in dry-run mode to see what would be changed
4. Check the backup directory to ensure backups exist before restoring
