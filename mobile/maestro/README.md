# Maestro smoke tests

End-to-end UI smoke tests that run against a real iOS Simulator or Android Emulator. Complements the Playwright web E2E (which runs against Expo's web bundle).

## Prerequisites

1. Install Maestro CLI:
   - macOS / Linux: `curl -Ls "https://get.maestro.mobile.dev" | bash`
   - Windows: install WSL2 and run the above inside WSL
2. Boot a simulator:
   - **iOS**: open Xcode -> Window -> Devices and Simulators -> pick a simulator
   - **Android**: open Android Studio -> Device Manager -> start an emulator
3. Build and install the app on the simulator:

```bash
cd mobile
npx expo prebuild
npx expo run:ios       # for iOS
npx expo run:android   # for Android
```

(First run is slow because it compiles native code.)

## Running flows

From `mobile/`:

```bash
npm run maestro:smoke
```

Or directly:

```bash
maestro test maestro/flows --include-tags smoke
```

Run a single flow:

```bash
maestro test maestro/flows/sign-in-smoke.yaml
```

## What's covered

- **launch-smoke** -- app starts, sign-in screen visible
- **sign-in-smoke** -- magic-link request flow (UI side only -- Mailpit is not polled)
- **social-buttons-smoke** -- Apple + Google buttons present

For magic-link callback testing, use the Playwright web E2E suite (`npm run test:e2e`).

## Authoring new flows

- Place YAML files under `maestro/flows/`
- Tag with `smoke` to be included in `npm run maestro:smoke`
- Use `testID` props from React Native components as Maestro `id` selectors
- Run `maestro studio` to interactively explore the running app and discover IDs
