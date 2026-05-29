# Release guide — BVisionry Connect (`com.bvisionry.connect`)

App identity, store-compliance flows (account deletion, block/report, privacy/
terms, Sign in with Apple, age gate), crash reporting and i18n are all in place.
This doc covers the remaining **human-only** steps to ship to the Play Store and
App Store. Everything else (version `1.0.0+1`, iOS entitlements wiring, export-
compliance flag, launcher icons + splash, release CI) is already wired on this
branch.

> The current launcher icon / splash is an **on-brand placeholder** (navy
> `#0F3460` + gold `#FFC107` connection mark). Replace it with final artwork
> before launch — see [§4](#4-replace-placeholder-artwork).

---

## 1. Android signing (required — Play rejects debug-signed bundles)

`android/app/build.gradle.kts` already reads signing config from
`android/key.properties` and falls back to debug signing only when it's absent.

Generate the upload keystore (keep it safe — and enable **Play App Signing** so
Google holds the app-signing key and you can reset a lost *upload* key):

```bash
keytool -genkeypair -v \
  -keystore connect-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias connect
```

Place it at `mobile_flutter/android/keystore/connect-release.jks` (gitignored),
then create `mobile_flutter/android/key.properties` (gitignored) from
`android/key.properties.example`:

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=connect
storeFile=../keystore/connect-release.jks
```

Build locally:

```bash
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

For CI, set the secrets listed at the top of
`.github/workflows/flutter-release.yml` and push a `v*` tag (or run the workflow
manually) to produce a signed `.aab` artifact.

## 2. iOS signing & capabilities (needs a Mac + Apple Developer account)

The entitlements file is now wired into all three Runner build configs
(`CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`), so Push and Associated
Domains apply at archive time. Remaining:

1. Set your **Apple Team ID** (10-char) — in Xcode select the Runner target →
   Signing & Capabilities → Team, **or** add `DEVELOPMENT_TEAM = <TEAMID>` to the
   Runner configs in `ios/Runner.xcodeproj/project.pbxproj`.
2. Replace `REPLACE_TEAM_ID` in `ios/ExportOptions.plist`.
3. In the Apple Developer portal, enable **Push Notifications** (APNs key) and
   **Associated Domains** for `com.bvisionry.connect`.
4. Archive & upload: `flutter build ipa --release --dart-define-from-file=env/prod.json`
   then upload via Xcode Organizer / Transporter.

`ITSAppUsesNonExemptEncryption=false` is already set, so no export-compliance
prompt on upload (the app uses only standard HTTPS/exempt crypto).

## 3. Deep-link association files (required for verified links to open the app)

The app's links use the **real** domain `connect.bvisionry.com`. Host these two
files on that domain — they are NOT in this repo (they live on the marketing
site, and need values you only have after signing setup).

`https://connect.bvisionry.com/.well-known/assetlinks.json` (Android):

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.bvisionry.connect",
    "sha256_cert_fingerprints": ["<SHA-256 of the Play App Signing certificate>"]
  }
}]
```

> Get the SHA-256 from Play Console → Release → Setup → App signing, **or**
> `keytool -list -v -keystore connect-release.jks -alias connect`.

`https://connect.bvisionry.com/.well-known/apple-app-site-association` (iOS — no
file extension, served as `application/json`):

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "<TEAMID>.com.bvisionry.connect",
      "paths": ["/p/*", "/sign-up", "/u/*"]
    }]
  }
}
```

Paths mirror the Android App Links intent-filter (`/p/*`, `/sign-up`) plus the
public investor pages (`/u/*`).

## 4. Replace placeholder artwork

Drop final brand art at the same paths and regenerate:

```bash
# assets/icon/icon.png             1024x1024, full logo on navy
# assets/icon/icon_foreground.png  1024x1024, transparent, centered (Android adaptive safe zone)
# assets/splash/splash_logo.png    transparent logo for the splash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

(`tool/gen_placeholder_icons.py` regenerates the current placeholders if needed.)

## 5. Store-console checklist (outside the codebase)

- **Privacy Policy URL** — host publicly; required by both consoles (the in-app
  Settings → Legal screen has the text, but the listing needs a hosted URL).
- **Play Data Safety** form — declare: voice recording (`RECORD_AUDIO`), photos,
  notifications, and advertising ID (`AD_ID`, pulled in by Firebase Analytics —
  remove it from the merged manifest if you don't use ads).
- **Apple App Privacy** nutrition labels.
- Screenshots, descriptions, age rating, support URL.
- TestFlight / internal-testing pass before production rollout.
