# mobile_flutter — BVisionry Connect (Flutter rebuild)

Sibling Flutter app to `../mobile/` (the React Native original). The
Supabase backend in `../supabase/` is **shared verbatim** — no schema,
RPC, or RLS change is introduced by the rebuild.

References:
- `../FLUTTER_REBUILD_SPEC.final.md` — the spec.
- `../docs/superpowers/plans/2026-05-25-flutter-rebuild-00-master.md` — phase index.
- `../docs/flutter-readme.md` — rebuild context + migration plan.

## Prerequisites

- Flutter 3.27.x stable, Dart 3.6.x
- Xcode 16+, Android Studio with SDK 34
- Docker (for local Supabase: `supabase start` from repo root)
- A `env/dev.json` filled in from `env/dev.json.example`

## Dev quickstart

```bash
cp env/dev.json.example env/dev.json
# fill in SUPABASE_ANON_KEY from `supabase status -o env`
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=env/dev.json
```

## Tests

```bash
# unit + widget
flutter test --dart-define-from-file=env/dev.json

# golden snapshots — refresh
flutter test --update-goldens

# integration (requires `supabase start`)
flutter test integration_test/ \
  --dart-define-from-file=env/ci.json \
  --dart-define=SUPABASE_SERVICE_ROLE_KEY=$(supabase status -o env | grep SERVICE_ROLE_KEY | cut -d= -f2)

# Maestro smoke
maestro run maestro/flows/launch_smoke.yaml

# RPC coverage
dart run tool/verify_rpc_coverage.dart

# i18n parity
flutter test test/core/i18n/locale_parity_test.dart

# coverage threshold (>= 70%)
flutter test --coverage
flutter test test/coverage_threshold_test.dart
```

## Build & release

### iOS

```bash
flutter build ipa --release \
  --dart-define-from-file=env/prod.json \
  --export-options-plist=ios/ExportOptions.plist
```

Required setup:
- `ios/Runner/GoogleService-Info.plist` (real, from Firebase console)
- `ios/Runner/Runner.entitlements` (committed)
- APNs key uploaded to Firebase
- Apple Developer team ID in `ios/ExportOptions.plist`

### Android

```bash
# 1) Generate keystore (one-time, OFF this machine in real life)
keytool -genkey -v -keystore android/keystore/connect-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias connect

# 2) Copy and fill key.properties
cp android/key.properties.example android/key.properties
# edit with the keystore passwords above.

# 3) Drop Firebase config
cp /path/to/google-services.json android/app/google-services.json

# 4) Build
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

### Sentry source-map upload

After a release build:

```bash
SENTRY_AUTH_TOKEN=... SENTRY_ORG=bvisionry SENTRY_PROJECT=connect-flutter \
dart run sentry_dart_plugin
```

Or, locally, copy `sentry.properties.example` -> `sentry.properties` and
fill in `auth.token`.

### Launcher icons + native splash

Source assets MUST be provided in:
- `assets/icon/icon.png` — 1024x1024, navy fill, gold `C` mark
- `assets/icon/icon_foreground.png` — 1024x1024, transparent bg, gold logo
- `assets/splash/splash_logo.png` — 512x512, gold on transparent

Then run:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Project layout

```
lib/
├── main.dart                  # bootstrap + telemetry + deep-link dispatch
├── app.dart                   # MaterialApp.router + theme + i18n
├── core/                      # design tokens, supabase client, routing, errors,
│                              # i18n, accessibility, widgets, push, analytics
└── features/                  # one folder per feature (auth, onboarding,
                               # profile, home, discovery, intros, chat,
                               # meetings, office_hours, opportunities,
                               # privacy, push, settings, verification,
                               # connections, media)

test/                          # unit + widget + golden tests
integration_test/              # 11 critical user-flow E2E tests
maestro/flows/                 # Maestro smoke flows
tool/                          # one-off scripts (RPC coverage, etc.)
```

## Conventions

- **State**: Riverpod (`AsyncNotifier` for queries, `StateNotifier` for
  local UI state).
- **Routing**: `go_router` with a redirect guard derived from session +
  profile.
- **Theming**: `ThemeExtension`s only — no inline hex in widgets.
- **i18n**: keys from `lib/core/i18n/locales/{en,es}.json`; helper
  `context.t('namespace.key')`. Parity is gated by
  `test/core/i18n/locale_parity_test.dart`.
- **Errors**: typed `AppException` subclasses; map via
  `mapPostgrestError` / `mapAuthError`.
- **Auth**: Supabase PKCE deep link `connect-mobile://auth?code=...`.
- **Universal links**: `https://connect.bvisionry.com/p/<handle>` — infra
  serves an Apple AASA file (see
  `../docs/flutter-readme.md#universal-links--infra-prerequisite`).

## OTA updates

Out of scope for the initial Flutter ship. See
`../docs/flutter-readme.md#ota--hot-patching` for the Shorebird follow-up
plan.

## Coverage target

70% line coverage. Run `flutter test --coverage` and inspect
`coverage/lcov.info`. The CI workflow enforces this via
`test/coverage_threshold_test.dart`.
