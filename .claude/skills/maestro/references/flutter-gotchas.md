# Flutter app gotchas

Flutter renders UI through its own engine, which causes two recurring problems when driving a Flutter app with Maestro on Android. Apply these workarounds **before** wasting time diagnosing — both look like Maestro/adb bugs but are Flutter rendering quirks.

## Black PNG from `adb screencap` and `mcp__maestro__take_screenshot`

**Symptom:** Both `adb exec-out screencap -p > shot.png` and `mcp__maestro__take_screenshot` return an identical small (~15.5 KB) all-black PNG. The app is clearly running — `logcat` shows FlutterJNI viewport metrics, the app responds to taps — but every screenshot is black.

**Cause:** Flutter's Impeller GLES backend (default since Flutter 3.10+) renders to a surface that SurfaceFlinger doesn't expose to `screencap` on many Android emulator GPU configurations. Skia rendering is fine; Impeller is what breaks the capture path.

**Fix:** Relaunch the app with Impeller disabled, which falls back to the Skia renderer:

```
adb shell am start -n <package>/.<MainActivity> --ez io.flutter.embedding.android.EnableImpeller false
```

For example, for BVisionRY Connect:

```
adb shell am start -n com.bvisionry.connect_mobile/.MainActivity --ez io.flutter.embedding.android.EnableImpeller false
```

After this, both `adb screencap` and `mcp__maestro__take_screenshot` work normally. The flag persists for the launch, so you can re-launch later without it once you're done capturing.

If you're driving via `flutter run`, pass `--no-enable-impeller` to the same effect. For release builds you can bake it into `AndroidManifest.xml`:

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
```

(But for tests this is overkill — the launch flag is enough.)

## `EditText` fields with only `hint:` and no usable selector

**Symptom:** `inspect_screen` reports a clickable `EditText` with `hint: "Email"` (or similar placeholder text), no `txt`, no stable `resourceId`, and the same class as ten other text fields on the screen. `tapOn { hint: "Email" }` fails immediately with `Unknown property: hint` because Maestro selectors only accept `text` / `id` / `index` / `point` / `position`.

**Cause:** Flutter's default `TextField` widget renders to a single `EditText` per field, with the placeholder living in `android:hint` (which `inspect_screen` surfaces as `hint`) rather than `text`. Without an explicit `Semantics` widget or `key:` wrapper in the Flutter code, there's no resourceId either.

**Workarounds, in order of preference:**

1. **Add a `Semantics(label: ...)` to the field in Flutter code.** This becomes the `a11y` field in the hierarchy, which Maestro reads via `text:`. This is the right fix if you control the source — it makes the app testable and accessible at the same time.

2. **Use `point: "X%,Y%"` taps**, measuring the field bounds from `inspect_screen`. Each hierarchy node has `bounds: "[L,T][R,B]"` in absolute pixels; convert to a percentage of the device size and use percentage form so the flow survives different device sizes. Example: an EditText with `bounds: "[40,1480][1040,1640]"` on a 1080×2400 device sits at roughly `(50%, 65%)` center. **This is the only practical option when you can't change the source** (e.g. driving someone else's app, or testing release builds).

3. **Use `index:` on the parent class**, e.g. `tapOn { id: "android.widget.EditText", index: 1 }`. Avoid this — `index:` numbering depends on traversal order and is fragile across UI changes. The previous walk of this app accidentally matched a launcher view with `id: ".*"` because the regex was too greedy.

When falling back to `point:`, also use `hideKeyboard` after each `inputText` so the next field's coordinate isn't covered by the IME.

## Why these aren't "bugs" — adjacent context

- The Impeller surface issue is tracked in [flutter/flutter#118866](https://github.com/flutter/flutter/issues/118866) and friends. Flutter team's position is "screencap is unsupported with Impeller on emulator GPUs"; the Skia fallback is the supported path for testing.
- Maestro's selector restriction is intentional — `text:` matching `hint:` would be ambiguous (a hint and an entered value can both be visible). The fix is to make fields semantically labeled in the source, which also helps screen readers.

Both workarounds are the established testing-on-Flutter pattern, not hacks.
