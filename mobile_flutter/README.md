# mobile_flutter — BVisionry Connect (Flutter rebuild)

Sibling Flutter app to `../mobile/` (the React Native original). The
Supabase backend in `../supabase/` is shared.

## Dev quickstart

```bash
# Copy and fill in your local Supabase keys
cp env/dev.json.example env/dev.json

# Run on web (quick smoke)
flutter run -d chrome --dart-define-from-file=env/dev.json

# Run on a simulator / connected device
flutter run --dart-define-from-file=env/dev.json
```

## Test

```bash
flutter test                       # unit + widget
flutter test --update-goldens      # refresh golden snapshots
flutter analyze
dart format --set-exit-if-changed lib test
```

## Codegen (run after editing freezed models / riverpod generators)

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project layout

See [`docs/superpowers/plans/2026-05-25-flutter-rebuild-00-master.md`](../docs/superpowers/plans/2026-05-25-flutter-rebuild-00-master.md).
