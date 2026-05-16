# BVisionRY Connect — Mobile (React Native + Expo)

The React Native rebuild of BVisionRY Connect. Slice 1 ships the foundation: Expo + Expo Router + Supabase + Firebase + Sentry + magic-link auth + a Playwright/Expo-Web validation loop.

## Requirements

- Node.js 20+
- npm 10+
- Local Supabase running (from the repo root: `npx supabase start`)
- For Android builds: Android Studio + an Android emulator
- For iOS builds: macOS + Xcode

## First-time setup

From the repo root:

```bash
npx supabase start
npx supabase gen types typescript --local > mobile/src/lib/supabase/types.gen.ts
```

From `mobile/`:

```bash
npm install
cp .env.example .env
# edit .env if your local Supabase anon key differs from the placeholder
```

## Run

```bash
# Web (preferred dev loop)
npm run web              # http://localhost:8081

# Android (requires emulator running)
npm run android

# iOS (macOS only)
npm run ios
```

## Verify

```bash
npm run typecheck
npm run lint
npm test
npm run test:e2e         # full Playwright magic-link flow against Mailpit
```

## Firebase setup (when ready)

Slice 1 ships with placeholder `google-services.json` / `GoogleService-Info.plist`. Analytics and Crashlytics are no-ops with placeholders.

To enable real Firebase:

1. Create a Firebase project at https://console.firebase.google.com/
2. Add an Android app with bundle ID `com.bvisionry.connect`; download the real `google-services.json` and overwrite the placeholder
3. Add an iOS app with bundle ID `com.bvisionry.connect`; download the real `GoogleService-Info.plist` and overwrite the placeholder
4. Set `EXPO_PUBLIC_FIREBASE_ENABLED=true` in `.env`
5. `npx expo prebuild --clean` to regenerate native projects

## Sentry setup (optional)

Set `EXPO_PUBLIC_SENTRY_DSN` in `.env`. Empty DSN = no-op.

## Project structure

See `docs/superpowers/specs/2026-05-15-slice1-foundation-design.md` for the full design.
