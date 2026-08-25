# Windows Defender / Windows Security Remover (kentang-grade)

⚠️ **WARNING — READ FIRST**
This disables Windows Defender Antivirus and Windows Security on Windows 10.
Your PC will be **UNPROTECTED** against viruses, ransomware, and drive-by attacks.
Only run this on a machine you accept the risk for, or where a third-party AV replaces it.
A `restore-defender.*` script is provided to undo everything.

## Files
- `disable-defender.ps1` — the actual logic (admin).
- `disable-defender.bat` — admin self-elevating launcher (visible).
- `disable-defender.vbs` — silent launcher (no window), for double-click / Task Scheduler.
- `restore-defender.ps1` / `.bat` / `.vbs` — re-enable everything.

## Usage
```
Right-click disable-defender.bat -> Run as administrator
   OR
Double-click disable-defender.vbs (silent)
```
Then **reboot**.

## The one thing scripts CANNOT do for you (do this first)
**Tamper Protection** blocks any script/registry from turning Defender off.
Turn it off manually before running:

> Windows Security → Virus & threat protection →
> Virus & threat protection settings → **Tamper Protection = Off**

If you skip this, `DisableAntiSpyware` is ignored and Defender stays on.

## Making it "permanent" (survives Windows Update)
The cleanest *permanent* method is **Group Policy** (no script needed,
and Windows Update won't silently re-enable it):

1. `Win+R` → `gpedit.msc`
2. Computer Configuration → Administrative Templates →
   Windows Components → Microsoft Defender Antivirus
3. **Turn off Microsoft Defender Antivirus** → Enabled
4. (Optional) Windows Components → Microsoft Defender Antivirus →
   Real-time Protection → **Turn off real-time protection** → Enabled
5. `gpupdate /force` then reboot.

On **Home** edition (no gpedit): import the registry the scripts write —
`HKLM\SOFTWARE\Policies\Microsoft\Windows Defender` `DisableAntiSpyware = 1`.

## What the script does
1. `Set-MpPreference` — kills real-time/behavior/cloud/archive/script scanning.
2. Writes `DisableAntiSpyware=1` policy key (the main off-switch).
3. Disables services: `WinDefend`, `SecurityHealthService`, `WdNisSvc`, `Sense`.
4. Disables Defender + Security Health scheduled tasks (they re-arm scanning).
5. Removes the Windows Security / Defender AppX packages.
6. Best-effort DISM removal of the Defender feature (Enterprise/Education only).
7. Blocks Defender telemetry hostnames in `hosts` (reversible).

## Restore
```
Right-click restore-defender.bat -> Run as administrator
   OR double-click restore-defender.vbs
```
Then reboot and run a signature update.

## Notes
- On Windows 10 Pro/Home the Defender *feature* cannot be DISM-removed
  (only Enterprise/Education). The policy + service disable still works.
- A major Windows Update can reset the policy; re-run or use Group Policy.
- This is intended for the user's own machine. Not a recommendation for
  shared/multi-user/production systems.
