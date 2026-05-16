---
name: maestro
description: Drive mobile apps and web pages via Maestro for UI automation, end-to-end tests, regression checks, visual review, screenshot capture, view-hierarchy inspection, or booting Android/iOS emulators when no device is running. Use this skill whenever the user wants Claude to interact with a running app — booting an emulator/simulator, installing an app, running flows, walking user journeys, validating screens, capturing screenshots for design review, debugging Maestro `UNAVAILABLE` or `tcp:7001` errors, or authoring/editing YAML flows. Also covers the adb fallbacks for plain screenshots and raw hierarchy when Maestro itself is overkill or down.
---

# Maestro skill

Maestro authors and runs declarative YAML UI flows on Android emulators, iOS simulators, real devices, and Chromium. The Maestro MCP server (`mcp__maestro__*`) is the primary surface; the `maestro` CLI is the fallback when the MCP misbehaves. Full command reference: https://docs.maestro.dev/llms-full.txt — fetch on demand for unfamiliar syntax.

## Core workflow

Always in this order. Skipping `inspect_screen` is the #1 cause of selectors that look right but never match.

1. `mcp__maestro__list_devices` — pick a `device_id` (mobile sim/emulator, or `chromium`). If empty, **boot one** (see `references/emulator-boot.md`) rather than aborting — that's part of the job.
2. `mcp__maestro__inspect_screen` — read the current view hierarchy. This is the ground truth for selectors. Authoring from a screenshot fails because rendered icons and decorative SVGs read like text visually but have no `text` attribute on the device.
3. `mcp__maestro__run { device_id, yaml }` — submit one full flow, not many single-step calls. The MCP validates syntax before executing.
4. Re-inspect after any UI change. Stale hierarchies cause selectors that worked once to silently fail.

For unfamiliar commands, conditionals, or multi-screen patterns, call `mcp__maestro__cheat_sheet` first. Don't guess YAML — the parser is strict about indentation and keyed vs. inline forms.

## Booting a device

If `list_devices` returns nothing, boot one yourself — don't stop the session asking the user. Quick reference:

- **Android**: `maestro start-device --platform=android` is the easiest path. For a specific AVD, run the emulator binary in the background and poll `adb shell getprop sys.boot_completed` until it returns `1`.
- **iOS** (macOS only): `xcrun simctl boot <udid>` then `open -a Simulator`.
- **Web**: pass `device_id: "chromium"` to the MCP — it boots Chromium for you.

Full procedure (including post-boot app install with `adb install` or `flutter run -d`, and how to wait correctly for cold-boot vs. snapshot-boot) is in `references/emulator-boot.md`.

## When to use which surface

- **MCP** (`mcp__maestro__*`) — default. Faster, no per-call JVM cold-start.
- **CLI** (`maestro test <flow.yaml>`, `maestro hierarchy`) — fallback when the MCP is unrecoverable, or when the user explicitly asks for the CLI. Note: `maestro view` and `maestro screenshot` are **not** real subcommands; use `maestro hierarchy` and `adb exec-out screencap` instead.
- **Skip Maestro entirely** for plain screenshots or raw hierarchy. `adb exec-out screencap -p > shot.png` and `adb shell uiautomator dump` are one-liners with no driver dependency. Reach for them when MCP is down or for a quick visual without authoring a flow.

## Authoring flows

Mobile flows declare `appId` and start with `launchApp`. Web flows declare `url` and start with `openLink`.

```yaml
appId: "com.example.myapp"
---
- launchApp
- tapOn: "Sign in"
- inputText: "user@example.com"
- assertVisible: "Welcome"
- takeScreenshot: home_screen
```

### Selector rules (the bites that recur)

- `text:` is a **full-string regex with IGNORE_CASE**, not a substring match. Use the entire visible string, or anchor with `.*` (e.g. `text: "Sign in.*"`). A common failure mode: copying just `"Sign in"` when the button reads `"Sign in to continue"`.
- The hierarchy's `a11y` field maps to `text:` in selectors. Never pass `a11y:` or `accessibilityText:` — Maestro doesn't recognize them.
- Copy `txt` values verbatim from `inspect_screen` output. Whitespace, casing, and trailing punctuation matter for the regex.
- Avoid hardcoded coordinates (`tapOn: { point: "500,1200" }`). They break across device sizes. Prefer `text:` / `id:` / `index:`, in that order.

## Flutter apps — apply the gotchas first

Flutter renders through its own engine and trips two issues that look like Maestro/adb bugs but aren't:

- **Screenshots come back as a 15.5 KB all-black PNG** even though the app is visibly running. This is Flutter's Impeller GLES backend; relaunch with `--ez io.flutter.embedding.android.EnableImpeller false` and capture works.
- **`TextField` widgets often expose only `hint:`** — not a valid Maestro selector key. Fall back to `point: "X%,Y%"` measured from `inspect_screen` bounds, or add `Semantics(label: ...)` to the source.

Apply these proactively when driving a Flutter app — don't waste a diagnostic round chasing what looks like a Maestro bug. Full procedure with launch commands, percentage-tap math, and the source-side `Semantics` fix in `references/flutter-gotchas.md`.

## Screenshots for visual review

Three mechanisms, ordered by when each wins:

- `mcp__maestro__take_screenshot` — image returned directly into context. Best for ad-hoc review of a single screen.
- `takeScreenshot: <name>` inside a flow — saved to `~/.maestro/tests/<timestamp>/`. Use when capturing several screens in one autonomous walk.
- `adb exec-out screencap -p > shot.png` then `Read` it — most reliable, no driver needed. Use when MCP is misbehaving or the device isn't running an app yet.

When giving design feedback, pair the screenshot with `inspect_screen` so feedback can cite exact resource IDs and bounds rather than visual impressions alone. Read the project's design-system docs first (look for files matching `*design*.md`, Storybook stories, or component READMEs) so the review is project-specific instead of generic UX advice.

## Autonomous walks of multiple screens

When the user asks Claude to "walk the app" or review many screens:

1. Run pre-flight (`references/recovery.md`) to avoid mid-walk failures from stale Maestro state.
2. Read project design docs so review is grounded in the project's own conventions.
3. Author **one** flow that visits each target screen and `takeScreenshot`s each.
4. Run via `mcp__maestro__run`; collect screenshots and the final hierarchy.
5. Review against the design system; cite files/lines for any code-level fix.
6. Iterate by editing code and re-running the same flow. Visual diff is straightforward when the flow path is fixed.

One full flow per walk beats many single-step calls — fewer driver round-trips, easier to re-run after a fix, and the YAML doubles as a regression artifact.

## When `UNAVAILABLE` happens

`mcp__maestro__run` returning `UNAVAILABLE` with `tcp:7001 closed` in the stack means the on-device driver APK was never installed even though Maestro thinks a session exists. This is almost always [mobile-dev-inc/maestro#3065](https://github.com/mobile-dev-inc/maestro/issues/3065).

Read `references/recovery.md` for the procedure. Don't chase `PATH` / `ANDROID_HOME` first — they're not the cause and waste a round.

## Resolving binaries

Don't hardcode paths. Resolve in order:

- `maestro`: `$env:MAESTRO_CLI` → `Get-Command maestro` / `which maestro` → `~/.maestro/bin/maestro`, `/usr/local/bin/maestro`.
- `adb`: `$env:ANDROID_HOME\platform-tools\adb.exe` → `Get-Command adb` / `which adb`.

If neither resolves, ask the user. The user may have an absolute-path memory entry (e.g. `reference_local_paths`) — check that before guessing. JetBrains terminals and other shells often don't inherit user `PATH`, so absolute paths are safer there.

## Things to avoid

- **`maestro view` / `maestro screenshot`** — not real subcommands. Use `maestro hierarchy` or `adb exec-out screencap`.
- **Multiple Maestro processes against the same platform simultaneously** — they race on `~/.maestro/sessions` and trip bug #3065. Serialize, or split across platforms (one Android, one web).
- **Trusting that the on-device driver persists** — the CLI reinstalls it per invocation, and the MCP skips reinstall whenever the sessions file claims a session already exists, even when the APK is gone.
- **Hardcoded coordinates in flows** — break across device sizes; prefer `text:` / `id:` / `index:`.
- **Authoring selectors from screenshots without inspecting** — icons read like words but have no `text`; the selector will silently never match.
