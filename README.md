# BVisionRY Connect

> Find the people who move your work forward.

**BVisionRY Connect** is a mobile-first, curated professional discovery network for **founders, leaders, builders, and investors**. Instead of an open follower graph, it pairs a daily, quality-ranked match feed with **warm introductions**, an **opportunities board**, **office hours**, and lightweight **meetings** — so the right conversations happen on purpose, not by cold outreach.

For the product story — audience, use cases, personas, and differentiators — see **[bvisionry-connect.md](./bvisionry-connect.md)**.

---

## Repository layout

| Path | What it is |
|------|------------|
| `mobile_flutter/` | The Flutter app (iOS · Android · Web). All product UI and client logic. |
| `supabase/` | Backend: Postgres migrations, Row-Level-Security policies, RPCs, Edge Functions, and pgTAP tests. |
| `bvisionry-connect.md` | Product & business overview (what it is, who it's for, use cases). |
| `CLAUDE.md` | Repo conventions / agent + environment notes. |

> Note: `docs/` is git-ignored and holds local-only design scratch (mockups, exports).

---

## Tech stack

**Client — `mobile_flutter/`**
- **Flutter** (Dart `^3.6`) targeting iOS, Android, and Web (CanvasKit)
- **Riverpod** for state, **go_router** for navigation, **freezed** + **json_serializable** for models
- **supabase_flutter** (auth, Postgres, Realtime, Storage) with PKCE auth and secure session storage
- **Firebase** (Analytics, Crashlytics, Messaging/push) and **Sentry** — all consent-gated
- Voice notes via `record` / `just_audio` / `audio_waveforms`; images via `image_picker` / `image_cropper`
- Design system: `google_fonts` (Dosis + Inter), `lucide_icons_flutter`, custom `ThemeExtension`s (colors, type, spacing, radii, shadows), light + dark themes
- Internationalised (English + Spanish)

**Backend — `supabase/`**
- **Postgres** with strict **Row-Level Security**; business logic in **SECURITY DEFINER RPCs** (e.g. `finish_onboarding`, `record_signup_consent`)
- **Edge Functions** (Deno): push dispatch, voice transcription, account deletion, goal-staleness reminders, meeting playbooks, goal-type inference, handle login
- **pgTAP** tests under `supabase/tests/`

---

## Getting started

### Prerequisites
- Flutter SDK `>=3.27` (Dart `^3.6`)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (Docker required) for the local backend

### 1. Start the backend (local)
```bash
supabase start          # boots Postgres, Auth, Storage, Studio; applies migrations
supabase status         # prints the local API URL + anon key
```
Local defaults: API `http://127.0.0.1:54321`, Studio `http://127.0.0.1:54323`.

### 2. Run the app
The app reads configuration from `--dart-define`s (see `mobile_flutter/lib/core/env.dart`):

```bash
cd mobile_flutter
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local anon key from `supabase status`>
```

| Dart-define | Default | Purpose |
|-------------|---------|---------|
| `SUPABASE_URL` | — | Supabase project / local API URL |
| `SUPABASE_ANON_KEY` | — | Supabase anon key |
| `INVITE_ONLY` | `false` | Gate sign-up behind an invite code + surface the waitlist |
| `FIREBASE_ENABLED` | `false` | Enable Firebase init + push/analytics |
| `SENTRY_DSN` / `SENTRY_ENV` | — / `dev` | Crash reporting |
| `APP_LINKS_HOST` / `APP_SCHEME` | placeholder / `connect-mobile` | Deep-link host + custom scheme |

> Production builds run `Env.requireProdInvariants()`, which throws if Supabase/host placeholders are left unset when `SENTRY_ENV=prod`.

### Web

```bash
# Local dev (Chrome, with hot reload):
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Release bundle (served statically):
flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
Serve the local backend's auth redirect on `http://localhost:8081` (matches `supabase/config.toml`).

---

## Quality

```bash
cd mobile_flutter
flutter analyze            # static analysis — must be clean
flutter test               # widget / golden / unit tests
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed / json / riverpod
```
Backend RLS and RPC behaviour is covered by **pgTAP** tests in `supabase/tests/` (run via the Supabase CLI).

---

## Trust, safety & compliance (built in)
- **Invite-only** onboarding with a waitlist fallback
- **18+ age gate** + explicit **Terms / Privacy consent** recorded server-side before access
- **Verification badges** (GitHub, custom-domain email, Crunchbase, portfolio) per role
- **Private mode**, **blocking**, **reporting**, sender-rate caps, and an account **suspension / appeal** flow
- GDPR/CCPA-minded: in-app **data export** and permanent **account deletion**

---

## Status
Pre-launch / launch-readiness. The client is feature-complete across discovery, intros, chat, meetings, opportunities, office hours, profile, settings, and privacy; the backend ships schema, RLS, RPCs, and Edge Functions. Monetization is intentionally open (see `bvisionry-connect.md`).
