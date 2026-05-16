# Booting a device for Maestro

When `mcp__maestro__list_devices` returns empty, boot one. This is part of the job — don't stop and ask the user unless the boot procedure itself fails.

## Android

### Path A — Maestro's built-in (simplest)

```
maestro start-device --platform=android
```

Picks or creates a default AVD and waits for boot. Good when you don't care which AVD is used.

### Path B — Specific AVD (when the user has a named AVD they want)

1. List available AVDs:
   ```
   <android-sdk>/emulator/emulator -list-avds
   ```
   Common SDK locations: `$env:ANDROID_HOME` (Windows), `~/Library/Android/sdk` (macOS), `~/Android/Sdk` (Linux).

2. Boot the AVD **in the background** — the binary blocks until the emulator window closes, so foreground execution will hang the session:
   ```
   <android-sdk>/emulator/emulator -avd <name>
   ```
   Use the harness's background-run flag (Bash `run_in_background: true`).

3. Wait for boot to complete by polling:
   ```
   adb shell getprop sys.boot_completed
   ```
   Returns `1` when ready. Cold boots take 30-90s, snapshot boots ~10-15s. Don't proceed until you see `1` — `adb devices` showing the device as `device` (not `offline`) is necessary but not sufficient; the system can be up before the launcher is.

4. Confirm with `mcp__maestro__list_devices` — it should now list the emulator.

### Installing the app after boot

- Plain APK: `adb install -r path/to/app.apk` (the `-r` reinstalls without uninstalling, preserving granted permissions where possible).
- Flutter project: `flutter run -d <device-id>` builds debug, installs, and launches in one step. Slower than a pre-built APK but always current.
- React Native: `npx react-native run-android` (similar end-to-end behavior).

## iOS (macOS only)

1. List simulators:
   ```
   xcrun simctl list devices available
   ```
2. Boot one (replace `<udid>` with the value from step 1):
   ```
   xcrun simctl boot <udid>
   ```
3. Surface the Simulator window (otherwise it boots headless):
   ```
   open -a Simulator
   ```
4. Install: `xcrun simctl install booted path/to/App.app`
5. Launch: `xcrun simctl launch booted <bundle-id>`

## Web

`device_id: "chromium"` to `mcp__maestro__run` boots Chromium automatically. Nothing to do beforehand.

## Verifying device readiness

Before authoring or running a flow, verify the device is fully ready:

- `adb devices` — should show `device` status (not `offline`, `unauthorized`, or `no permissions`).
- `mcp__maestro__list_devices` — must list the device. If `adb devices` shows it but the MCP doesn't, run pre-flight from `recovery.md` (the MCP's session bookkeeping is stale).
- For freshly-booted Android: `adb shell getprop sys.boot_completed` returns `1`.

If the device shows `unauthorized` on Android, the user needs to tap "Always allow from this computer" on the device's RSA fingerprint dialog — Claude can't dismiss it remotely.

## Why not just always boot via `start-device`?

`maestro start-device` is convenient but opaque about which AVD it picks, which makes debugging harder when the wrong device is targeted. For project work where the user has a specific AVD set up (with a particular API level, screen size, or pre-installed Google Play services), Path B is more predictable. Use `start-device` for ad-hoc exploration, the explicit path for repeatable test runs.
