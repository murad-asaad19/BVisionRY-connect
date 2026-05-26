# BVisionry Connect — Flutter rebuild

`mobile_flutter/` is a Flutter rebuild of the React Native app at
`mobile/`. The Supabase backend in `supabase/` is shared verbatim — no
schema, RPC, or RLS changes are introduced by the rebuild.

## Why rebuild

See `FLUTTER_REBUILD_SPEC.final.md` §0 for the rationale. tl;dr: tighter
native control, single rendering layer, smaller binary, longer-term
maintainability for our small team.

## Plan suite

`docs/superpowers/plans/2026-05-25-flutter-rebuild-{00..15}-*.md`. Phase
15 (this PR's parent) is the final polish + release configuration phase.

## Migration approach

- `mobile/` (RN) and `mobile_flutter/` (Flutter) ship side-by-side
  during the rollout.
- App Store / Play Store: replace the binary once parity is verified
  end-to-end (acceptance via the integration_test suite + a 1-week
  internal beta).
- Backend: unchanged. RN and Flutter clients can coexist against the
  same Supabase project indefinitely.
- Bundle ID is `com.bvisionry.connect` (matches the existing
  Production listing). Existing installs upgrade in place.

## OTA / hot patching

EAS Update (used by the RN app) does not have a 1:1 Flutter equivalent.
Two options exist:

- **Shorebird** (`shorebird.dev`) — Dart-aware code-push for Flutter.
  Recommended if rapid hot-patching is required.
- **CodePush** (Microsoft) — JS-centric; **not** a fit for compiled
  Dart.

**For the initial Flutter ship, OTA is OUT OF SCOPE.** All updates flow
through the App Store / Play Store. Revisit Shorebird in a follow-up
phase once the rebuild is in production for ≥ 30 days and we have
evidence of the operational need for hot-patching.

## Universal Links — Infra Prerequisite

iOS universal links require
`https://connect.bvisionry.com/.well-known/apple-app-site-association`
served by the marketing site. Coordinate with infra before TestFlight
submission. Android intent-filters use `autoVerify=true` and require the
same Apple AASA + a Digital Asset Links file at
`/.well-known/assetlinks.json`.

## Contact

See `CLAUDE.md` for build/test conventions used by AI agents in this
repo.
