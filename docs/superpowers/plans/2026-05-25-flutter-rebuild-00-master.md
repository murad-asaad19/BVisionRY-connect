# BVisionry Connect Flutter Rebuild — Master Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement each phase plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter 3.x rebuild of BVisionry Connect at `mobile_flutter/` (sibling to existing `mobile/` RN app), preserving the unchanged Supabase backend, full i18n parity, all features documented in `FLUTTER_REBUILD_SPEC.final.md`, with visual fidelity to `connect-full-app-gallery.html`.

**Architecture:** Riverpod for state, `go_router` for navigation, `supabase_flutter` for backend, `firebase_*` for push, Material 3 + custom `ThemeExtension` for design tokens, file-based feature folders mirroring the spec's §6 inventory. TDD throughout, with widget/unit/integration tests per phase.

**Tech Stack:**
- Flutter 3.27.x stable / Dart 3.6.x
- `flutter_riverpod` 2.6.x + `riverpod_annotation` + `riverpod_generator`
- `go_router` 14.x
- `supabase_flutter` 2.x
- `firebase_core` 3.x / `firebase_messaging` 15.x / `firebase_analytics` 11.x / `firebase_crashlytics` 4.x
- `sentry_flutter` 8.x
- `google_fonts` 6.x (Dosis + Inter)
- `lucide_icons_flutter` (Dart port of Lucide)
- `image_picker` 1.x + `image_cropper` 8.x + `flutter_image_compress`
- `record` 5.x + `just_audio` 0.9.x
- `flutter_secure_storage` 9.x (Supabase session)
- `shared_preferences` 2.x (Zustand-equivalent)
- `cached_network_image` 3.x
- `intl` + custom JSON i18n loader (ports `en.json`/`es.json` from RN)
- `freezed` 2.x + `json_serializable` 6.x (models)
- `formz` 0.7.x (form state)
- `dart_jsonwebtoken` (only if needed; supabase_flutter handles most)
- `add_2_calendar` or hand-rolled ICS (matches RN's `ics.service.ts`)
- `app_links` 6.x (universal/deep links)
- Test deps: `flutter_test`, `mocktail`, `golden_toolkit`, `patrol` (integration), `integration_test`

---

## Phase Decomposition

Each phase produces working, testable software on its own and lives in its own plan file. Phases are ordered by dependency; later phases assume earlier ones are merged.

| # | Plan file | Scope | Depends on |
|---|---|---|---|
| 01 | `2026-05-25-flutter-rebuild-01-foundation.md` | Project init, design tokens, theme, routing skeleton, Supabase client, i18n loader, env, Riverpod, error infrastructure, base UI primitives | — |
| 02 | `2026-05-25-flutter-rebuild-02-auth.md` | Session lifecycle, sign-in/up, magic link, social OAuth, handle-login edge function, error map, AuthShell, suspended screen | 01 |
| 03 | `2026-05-25-flutter-rebuild-03-onboarding.md` | 4-step wizard (Goal → Identity → Roles → About) + `infer-goal-type` integration + draft persistence | 01, 02 |
| 04 | `2026-05-25-flutter-rebuild-04-profile.md` | Own profile, edit profile, public profile by handle, profile signals, GitHub verification, share, goal refresh | 01, 02, 03 |
| 05 | `2026-05-25-flutter-rebuild-05-discovery.md` | Home tab daily matches, search, filters, thin-pool state, match-reason chips | 01, 02, 04 |
| 06 | `2026-05-25-flutter-rebuild-06-intros.md` | Direct intros (send/accept/decline/expire), inbox, intro detail, warm intros (`send_warm_request`, `forward_warm_intro`, `suggest_warm_intros`), forwarder sheet | 01, 02, 04 |
| 07 | `2026-05-25-flutter-rebuild-07-chat.md` | Conversation list, text/image/voice messages, edit/delete, reads/mutes, typing indicator, Realtime, voice transcript | 01, 02, 06 |
| 08 | `2026-05-25-flutter-rebuild-08-meetings.md` | Propose/confirm/decline/cancel, meeting card chat embed, ICS export, post-meeting review, AI playbook | 01, 02, 07 |
| 09 | `2026-05-25-flutter-rebuild-09-office-hours.md` | Host settings + windows, slot materialization view, booking, cancel-booking, my-bookings | 01, 02, 04, 08 |
| 10 | `2026-05-25-flutter-rebuild-10-opportunities.md` | Feed, create/edit/close, detail, express interest, my opportunities, interested list, push tap routing | 01, 02, 04 |
| 11 | `2026-05-25-flutter-rebuild-11-privacy.md` | Block/unblock, blocked list, report modal (profile/message/intro), quote-aware message reports | 01, 02 |
| 12 | `2026-05-25-flutter-rebuild-12-push.md` | FCM init (gated), token register/unregister, foreground toast, background tap routing, suppression in active conversation (DONE — Phase 13 consumes `notificationPrefsProvider`) | 01, 02, 07 (activeConversationProvider) |
| 13 | `2026-05-25-flutter-rebuild-13-settings.md` | Settings home, account, privacy toggles, notification matrix, blocked, verification, office-hours entry, help, legal, export-data, delete-account, language toggle | 01, 02, 09, 11, 12 |
| 14 | `2026-05-25-flutter-rebuild-14-telemetry.md` | Sentry (gated by telemetryStore + DSN), Firebase Analytics/Crashlytics (gated by `Env.firebaseEnabled` + telemetryStore), telemetry store with GDPR opt-out, SentryErrorBoundary, main.dart boot-sequence gate on `telemetryReadyProvider`, sign-out signOutReset propagation, build-time symbol upload via `sentry_dart_plugin` (config filled in Phase 15) | 01, 02, 12, 13 |
| 15 | `2026-05-25-flutter-rebuild-15-polish-e2e.md` | Visual polish (gradients, animations, skeletons), accessibility audit, golden tests, Patrol E2E flows, Maestro smoke, release configuration (iOS/Android signing, EAS-equivalent), README | all |

---

## Shared Conventions (all phase plans MUST follow)

### Directory layout

All Flutter code lives under `mobile_flutter/`. The repository tree:

```
mobile_flutter/
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml                          # Only if using gen-l10n; we use a custom JSON loader (§i18n below)
├── android/                           # platform shells generated by flutter create
├── ios/
├── lib/
│   ├── main.dart                      # Entry: WidgetsFlutterBinding + Riverpod ProviderScope + RootApp
│   ├── app.dart                       # RootApp: MaterialApp.router + theme + i18n bootstrap
│   ├── core/
│   │   ├── env.dart                   # dart-define-backed env (SUPABASE_URL/ANON_KEY/SENTRY/FIREBASE flags)
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # ThemeExtension<AppColors>
│   │   │   ├── app_typography.dart    # ThemeExtension<AppTypography>
│   │   │   ├── app_spacing.dart       # ThemeExtension<AppSpacing>
│   │   │   ├── app_radii.dart         # ThemeExtension<AppRadii>
│   │   │   └── app_theme.dart         # buildAppTheme(Brightness) → ThemeData
│   │   ├── supabase/
│   │   │   ├── supabase_client.dart   # Provider, secure-storage session storage
│   │   │   └── session_storage.dart   # flutter_secure_storage-backed LocalStorage impl
│   │   ├── i18n/
│   │   │   ├── i18n.dart              # AppLocalizations Riverpod provider + helper t()
│   │   │   ├── locale_loader.dart     # Loads en.json / es.json from assets
│   │   │   ├── locale_notifier.dart   # StateNotifier<Locale>
│   │   │   └── locales/               # en.json, es.json (copied from mobile/src/lib/i18n/locales/)
│   │   ├── routing/
│   │   │   ├── app_router.dart        # GoRouter config
│   │   │   ├── routes.dart            # named-route constants
│   │   │   └── route_guard.dart       # Next-route gate (mirrors useNextRoute)
│   │   ├── errors/
│   │   │   ├── app_exception.dart     # typed exception classes per SQLSTATE
│   │   │   ├── error_map.dart         # PostgrestException → i18n key
│   │   │   └── error_boundary.dart    # ErrorBoundary widget (Sentry-aware)
│   │   ├── analytics/
│   │   │   └── telemetry.dart         # Sentry/Crashlytics/Analytics gated initializers
│   │   ├── push/
│   │   │   ├── firebase_init.dart     # gated init
│   │   │   ├── fcm_service.dart
│   │   │   └── notification_route.dart
│   │   ├── widgets/                   # Shared UI primitives (Button, Card, Pill, …) — full list in Phase 1
│   │   └── utils/
│   │       ├── result.dart            # Result<T, E> for service-layer returns
│   │       └── debounce.dart
│   ├── features/                      # Mirrors mobile/src/features/ exactly (16 folders)
│   │   ├── auth/
│   │   │   ├── data/                  # services + repository + models
│   │   │   ├── domain/                # entities + value objects + use-cases (if needed)
│   │   │   ├── presentation/          # screens + widgets + controllers (Riverpod notifiers)
│   │   │   └── auth_providers.dart    # Riverpod providers entrypoint
│   │   ├── chat/ …
│   │   ├── connections/ …
│   │   ├── discovery/ …
│   │   ├── home/ …
│   │   ├── intros/ …
│   │   ├── media/ …
│   │   ├── meetings/ …
│   │   ├── office_hours/ …
│   │   ├── onboarding/ …
│   │   ├── opportunities/ …
│   │   ├── privacy/ …
│   │   ├── profile/ …
│   │   ├── push/ …
│   │   ├── settings/ …
│   │   └── verification/ …
│   └── shared_models/                 # DB row types generated from Supabase TS (see "Model generation" below)
├── test/                              # unit + widget tests, mirrors lib/ layout
│   ├── core/
│   ├── features/
│   └── helpers/
│       ├── pump.dart                  # pumpAppWith({overrides, locale, …})
│       ├── fake_supabase.dart         # Stub PostgrestClient + GoTrueClient
│       └── golden_helpers.dart
├── integration_test/                  # Patrol E2E flows
└── assets/
    ├── fonts/                         # If we self-host (otherwise google_fonts handles)
    ├── icons/                         # Brand glyphs
    └── images/
```

### Naming conventions

- Files: `snake_case.dart`.
- Classes / enums / extensions: `PascalCase`.
- Providers: `xxxProvider` (lowerCamelCase) using `riverpod_generator` annotations where possible.
- Test files: mirror source path; suffix `_test.dart`.
- Golden test files: mirror source path; suffix `_golden_test.dart`; goldens stored at `test/goldens/`.

### Test discipline (TDD — all phases)

Every task is `RED → GREEN → REFACTOR → COMMIT`:
1. Write the failing test.
2. Run it; verify it fails with the expected message.
3. Write the **minimal** implementation to pass.
4. Run it; verify it passes.
5. Commit with conventional-commit format (`feat:`, `fix:`, `test:`, `refactor:`, `chore:`).

Test commands (defined in Phase 1):
- Unit/widget: `flutter test`
- Single file: `flutter test test/features/auth/sign_in_screen_test.dart`
- Goldens: `flutter test --update-goldens test/features/auth/sign_in_screen_golden_test.dart`
- Integration: `flutter test integration_test/auth_smoke_test.dart -d <device-id>`
- Analyzer: `flutter analyze`
- Format: `dart format --set-exit-if-changed lib test`

### Commit cadence

- After every passing test (≤ 5 minutes of work).
- Conventional commits: `feat(scope): subject`, `test(scope): subject`, etc. Scope = phase or feature name (e.g. `auth`, `chat`, `theme`).
- Push to a feature branch per phase: `flutter/phase-NN-<name>`.

### Supabase RPC binding

All RPCs from spec §3 are exposed via typed Dart wrappers in `lib/features/<feature>/data/<feature>_service.dart`. Each wrapper:
1. Calls `supabase.rpc('<name>', params: {...})`.
2. Catches `PostgrestException` and maps via `core/errors/error_map.dart` to a typed `AppException` whose `i18nKey` matches the React Native `errorMap.ts` mapping.
3. Returns `Result<Model, AppException>` (or throws — phase plans pick one convention per service; see Phase 1).

### Model generation

Run `supabase gen types dart --schema public > lib/shared_models/db_types.dart` (Supabase CLI ≥ 2.x supports Dart generation; if missing, manually port the TS types from `mobile/src/lib/supabase/types.gen.ts` to Dart `freezed` models). Each phase plan specifies which models it needs.

### Theme tokens (locked)

Colors, typography, and spacing tokens are locked in Phase 1 and referenced by name everywhere else. Source of truth: spec §8 + gallery HTML lines 11–31. Body font is **Inter** (per spec §17.11), not Overlock; the gallery's Overlock choice is overridden by the spec.

### i18n strategy

We do NOT use Flutter's gen-l10n (ARB files). We port the existing JSON files verbatim from `mobile/src/lib/i18n/locales/en.json` and `es.json` (643 keys each) and load them via a custom `LocaleLoader` that supports `{{var}}` substitution and `_one/_other` plurals (i18next v4 plural-format).

Justification: keeping the JSON files lets us re-use the existing translator workflow and reach perfect parity without re-keying.

### Routing convention

- `go_router` with named routes declared in `core/routing/routes.dart`.
- Route paths match spec §7.1 (`/sign-in`, `/onboarding/goal`, `/chats/:id`, `/p/:handle`, …).
- Deep-link scheme `connect-mobile://` + universal links `https://${EXPO_PUBLIC_APP_LINKS_HOST}` (read from `APP_LINKS_HOST` Dart-define).
- A single `routeGuardProvider` (Riverpod) computes the next route from `(session, profile, suspended_at, onboarded)` exactly per spec §5.3.
- Push-tap deep-link routing per spec §7.4 implemented in `core/push/notification_route.dart`.

### Realtime convention

Each feature exposes a `useRealtime<X>(id)` hook-equivalent: a Riverpod `StreamProvider` that subscribes to `supabase.channel(...).on(postgres_changes/broadcast)`, invalidates dependent providers on event, and cleans up on dispose. Implementations per Phase 7 / 8.

### Environment variables

Pass via `--dart-define` at build time. The full list lives in `lib/core/env.dart`:

| `--dart-define` key | Maps to | Required for |
|---|---|---|
| `SUPABASE_URL` | `Env.supabaseUrl` | always |
| `SUPABASE_ANON_KEY` | `Env.supabaseAnonKey` | always |
| `SENTRY_DSN` | `Env.sentryDsn` | telemetry |
| `SENTRY_ENV` | `Env.sentryEnv` | telemetry |
| `FIREBASE_ENABLED` | `Env.firebaseEnabled` (bool) | FCM/Analytics |
| `APP_LINKS_HOST` | `Env.appLinksHost` | universal links / prod |
| `APP_SCHEME` | `Env.appScheme` (defaults to `connect-mobile`) | deep links |
| `EAS_PROJECT_ID` | `Env.easProjectId` | parity with RN release tooling (not actively used by Flutter) |

A `--dart-define-from-file=env/dev.json` (gitignored) holds local overrides; `env/dev.json.example` is committed.

---

## Execution Order & Parallelism

- **Sequential prefix:** Phase 1 → Phase 2. These set foundation and session, and everything downstream depends on them.
- **Parallel cluster (after Phase 2):** Phases 3, 4 can start. Once Phase 4 is in, Phases 5, 6, 10, 11 can all proceed in parallel.
- **Late cluster:** Phases 7 (after 6), 8 (after 7), 9 (after 8). Phase 12 picks up phase-by-phase route wires.
- **Polish/Settings:** Phase 13–15 last.

This means after Phase 2 lands, we can run up to 5 parallel subagents on independent feature plans.

---

## Self-Review checklist (executed by the master plan author after all phase plans are written)

- [ ] Every spec section (§2 tables, §3 RPCs, §4 edge functions, §5 auth, §6 features, §7 routing, §8 design, §9 i18n, §10 push, §11 telemetry, §12 AI, §13 media, §14 realtime, §15 testing, §16 build, §17 gaps) maps to at least one task in some phase plan.
- [ ] Type names used across phase boundaries are consistent (e.g. `IntroState` enum, `MeetingState` enum, `Profile` model).
- [ ] No placeholder text in any phase plan ("TBD", "implement later", etc.).
- [ ] Test commands and file paths in every phase match the convention defined here.
- [ ] Phase 1's UI primitives cover every widget used in any later phase.

---

## How to execute this plan suite

1. Read Phase 1, execute it task-by-task, commit at every green.
2. After Phase 1 merges, read Phase 2 and execute the same way.
3. After Phase 2 merges, dispatch parallel subagents on Phases 3 + 4 (then 5, 6, 10, 11 after 4 lands).
4. For each phase, use `superpowers:subagent-driven-development` (fresh subagent per task, review between tasks) OR `superpowers:executing-plans` (inline batch). The user has previously preferred inline execution with end-of-plan review (see `feedback_execution_speed.md`).
