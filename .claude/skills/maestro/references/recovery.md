# Maestro recovery procedures

Two scenarios, one fix. Pre-flight runs proactively before a long autonomous session; `UNAVAILABLE` recovery runs reactively when the MCP starts returning errors mid-session. Both apply the same procedure: ensure exactly one Maestro JVM is running, clear the stale sessions file, and let a single clean MCP subprocess respawn.

## Pre-flight

Run before any autonomous session that will drive the app for more than a few minutes — the cost (~30 seconds) is much smaller than re-running a 20-step walk after it fails halfway.

1. Find Maestro JVM processes:
   - Windows: `Get-WmiObject Win32_Process -Filter "Name='java.exe'" | Where-Object { $_.CommandLine -match 'maestro' }`
   - macOS / Linux: `ps -ef | grep maestro.cli.AppKt`
2. If more than one MCP subprocess is running, kill the extras. Multiple processes race to write `~/.maestro/sessions` and trigger bug #3065.
   - Windows: `Stop-Process -Id <ids> -Force`
   - macOS / Linux: `kill <pids>`
3. Delete the stale sessions file:
   - Windows: `C:\Users\<user>\.maestro\sessions`
   - macOS / Linux: `~/.maestro/sessions`
4. Reconnect the MCP via `/mcp` (or restart Claude Code) so a single clean subprocess spawns.

Skip pre-flight on quick one-off interactions; the overhead isn't worth it for a single screenshot.

## UNAVAILABLE recovery

`UNAVAILABLE` with `tcp:7001 closed` in the stack means the on-device driver APK was never installed even though Maestro believes a session exists. Almost always [mobile-dev-inc/maestro#3065](https://github.com/mobile-dev-inc/maestro/issues/3065).

Confirm the symptom before applying the fix — applying it blindly when the cause is something else (device disconnected, wrong `device_id`) just wastes time:

- `adb -s <device> shell pm list packages | grep maestro` → empty (no driver installed on device)
- `adb forward --list` → no Maestro entry (no `tcp:7001` forward set up)

If both confirm, run the pre-flight steps above. The fix is identical: kill stale processes, clear the sessions file, restart the MCP, and the next `list_devices` / `run` call will reinstall the driver cleanly.

Do **not** start with `PATH` or `ANDROID_HOME` adjustments — they're not the cause of #3065, and chasing them delays the actual fix.

## Why this works

Maestro's session bookkeeping lives in `~/.maestro/sessions`. When a process exits uncleanly (or two processes write the file simultaneously), the file claims a session is active when no driver is actually installed on the device. Subsequent MCP calls trust the file, skip the driver install, and immediately try to talk to `tcp:7001` — which nothing is listening on. Clearing the file forces the next call to reinstall the driver and re-establish the forward.
