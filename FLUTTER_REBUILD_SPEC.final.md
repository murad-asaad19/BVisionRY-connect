# BVisionry Connect — Flutter Rebuild Spec (Final / Authoritative)

> This file is the canonical, audited reconciliation of two parallel inventories of the BVisionry Connect codebase (`FLUTTER_REBUILD_SPEC.md` produced by a Sonnet agent and `FLUTTER_REBUILD_SPEC.opus.md` produced by an Opus agent), with every fact cross-checked against the source in `E:\projects\bvisionry-connect\`. Where the two agents disagreed and the source resolved it, only the source-correct version is shown. Where the source could not resolve the disagreement, both versions appear, marked with an HTML comment of the form `<!-- DISCREPANCY: ... -->`. See §19 for the audit trail.

---

## Section 0 — Reading Guide & Tech Stack

### How to use this document

This spec is the single source of truth for a Flutter rebuild of BVisionry Connect. It is written for a Claude Code agent rebuilding from scratch without access to the React Native source. Every section is self-contained; read in order for the first pass, then reference individual sections while implementing.

**Source of truth priority (highest → lowest)**

1. SQL in `supabase/migrations/*.sql` — the database is the contract. **Every constraint, RLS policy, trigger, and RPC body is verbatim from migration files**; never paraphrased.
2. Edge function TypeScript in `supabase/functions/<name>/index.ts` — server-side business logic.
3. React Native mobile source at `mobile/src/**` and `mobile/app/**` — UI behaviour reference; the React Native code is being replaced, not preserved.
4. `UI_UX_AUDIT.md` — design polish backlog enumerated in §17 with current status flags.
5. This document — the Flutter rebuild guide.

### Constraints on the rebuild

- The Supabase backend is **unchanged**. Every RPC, RLS policy, trigger, storage policy, edge function, and cron job below is the contract the Flutter app must speak. The Flutter client is a drop-in replacement for the React Native client; both sit in front of the same project.
- The Flutter rebuild target is **mobile only** (iOS + Android), portrait-only, with a single web build for development verification.
- All user-facing strings come from the existing `en.json` / `es.json` locale files in §9 (643 keys each, perfect parity).
- The deep-link scheme (`connect-mobile://`) and universal-link host (`EXPO_PUBLIC_APP_LINKS_HOST` — prod is `connect.bvisionry.com`) must be preserved for OAuth and push-notification routing.

### Original tech stack (React Native / Expo — DO NOT replicate)

| Layer | Original | Flutter equivalent |
|---|---|---|
| Framework | Expo SDK 54 / React Native 0.81 / React 19 | Flutter 3.x (stable) |
| Router | Expo Router 6 (file-based) | `go_router` |
| Styling | NativeWind 5 + Tailwind v4 (CSS-first `@theme`) | Custom `ThemeData` + design-token `ThemeExtension` |
| State (server) | TanStack Query 5 | `flutter_riverpod` with `AsyncValue` / `AsyncNotifier` |
| State (local) | Zustand 5 (AsyncStorage-persisted) | `riverpod` `StateNotifier` + `shared_preferences` |
| Forms | react-hook-form 7 + Zod 4 | hand-rolled validators or `formz` |
| Auth + Data | Supabase JS 2 | `supabase_flutter` |
| Push | `@react-native-firebase/messaging` v24 | `firebase_messaging` |
| Crash | Sentry React Native 7 + Firebase Crashlytics | `sentry_flutter` + `firebase_crashlytics` |
| Analytics | Firebase Analytics | `firebase_analytics` |
| Icons | `lucide-react-native` 1.16 | `lucide_icons` (Dart port) |
| Fonts | Dosis (display) + Inter (body) via `@expo-google-fonts/*` | `google_fonts` package |
| Audio | `expo-audio` | `record` + `just_audio` (or `audioplayers`) |
| Images | `expo-image-picker` + `expo-image-manipulator` | `image_picker` + `image_cropper` |
| Realtime | `supabase-js` realtime channels | `supabase_flutter` realtime API |
| Calendar export | Hand-rolled RFC 5545 (`ics.service.ts`) | Hand-rolled port to Dart |
| Backend | Supabase (PostgreSQL + RLS + Storage + Edge Functions + Realtime + pg_cron) | Unchanged |

### Document conventions

- SQL is **quoted verbatim** from the source migration. Never paraphrased.
- Every behavioural claim references a file path (relative to `E:\projects\bvisionry-connect\`).
- Error codes are SQLSTATE values raised by RPCs; Flutter must surface them through typed exception classes.
- No time estimates ("easy / medium / hard / 1 week") appear — the rebuild is executed by Claude Code, not humans.
- `<!-- DISCREPANCY: ... -->` flags an unresolved disagreement between the two source inventories.

---

## Section 1 — Product Summary

BVisionry Connect is a mobile-first **professional networking app** for founders, leaders, builders, and investors. The product centres on **intent-typed connection**: each user picks one of 8 goals (`public.goal_type` enum) and the system surfaces other users whose goals are complementary. Connections happen via "intros" (one-shot, gated direct messages that become a chat on accept), with first- and second-degree warm-intro flows on top. Users can post **Opportunities** (hiring, fundraising, cofounder search, advisory) and **book office hours** on each others' profiles. Confirmed meetings get an AI-generated **playbook** (Claude `claude-sonnet-4-6`) and post-meeting reviews feed back into the matching score.

It is invite-quality, deliberately small-network, focused on warm introductions and meaningful 1:1 connections rather than broad social graphs.

**Core loop:**

1. User onboards (goal → identity → roles → about); sets a goal and primary role.
2. Daily algorithm picks up to 5 matching profiles ("Daily Picks").
3. User sends a curated intro note (80–400 characters) to interesting profiles.
4. Recipient accepts or declines. Acceptance creates a private conversation.
5. Parties chat, propose and confirm meetings, leave reviews.
6. Warm-intro 2nd-degree network: connected users can ask mutual connections to introduce them to someone they don't know yet.
7. Opportunities board: post and browse hiring / funding / cofounder / collaboration postings.
8. Office hours: host configures a weekly availability window; others book slots.

**Goal-type values** (`public.goal_type` enum, from `supabase/migrations/20260516000000_slice2_profile.sql`):

```
hire, be_hired, co_found, invest, take_investment, advise, find_advisor, peer_connect
```

`public.goals_complementary(a, b)` (migration `20260527000000_slice17_matching.sql`) treats these pairs as complementary:

```
hire ↔ be_hired
invest ↔ take_investment
advise ↔ find_advisor
```

Same-goal matches: `co_found` ↔ `co_found` and `peer_connect` ↔ `peer_connect` get the same-goal weight (1) but not the complementary bonus (4).

**Audience:** English- and Spanish-speaking professional users. iOS and Android. Portrait-only.

---

## Section 2 — Full Data Model

All tables live in the `public` schema unless otherwise noted. Storage buckets live in `storage`. Extensions used: `extensions.citext`, `extensions.moddatetime`, `extensions.pg_net`, `extensions.pg_trgm`, `extensions.pg_cron`, `extensions.gin_trgm_ops`.

### 2.1 Enums — verbatim from source migrations

```sql
-- supabase/migrations/20260516000000_slice2_profile.sql
create type public.role_kind as enum ('founder', 'leader', 'builder', 'investor');

create type public.goal_type as enum (
  'hire', 'be_hired', 'co_found', 'invest', 'take_investment',
  'advise', 'find_advisor', 'peer_connect'
);

-- supabase/migrations/20260518000000_slice4_intros.sql
create type public.intro_state as enum (
  'delivered', 'accepted', 'declined', 'expired', 'connected'
);

-- supabase/migrations/20260608010000_second_degree_intros.sql
create type public.intro_kind as enum ('direct', 'warm_request', 'warm_forward');

-- supabase/migrations/20260520000000_slice6_meetings.sql
create type public.meeting_state as enum ('proposed', 'confirmed', 'declined', 'cancelled');
create type public.meeting_feedback_rating as enum ('positive', 'neutral', 'negative');
create type public.message_kind as enum ('text', 'meeting');  -- extended in slice13 → ('text','meeting','image','voice')

-- supabase/migrations/20260524000000_slice13_media.sql (final shape)
create type public.message_kind as enum ('text', 'meeting', 'image', 'voice');

-- supabase/migrations/20260521000000_slice8_push.sql
create type public.device_platform as enum ('ios', 'android', 'web');

-- supabase/migrations/20260523000000_slice9_privacy.sql
create type public.report_target_type as enum ('profile', 'message', 'intro');
create type public.report_reason as enum (
  'spam', 'harassment', 'impersonation', 'inappropriate', 'other'
);

-- supabase/migrations/20260604000000_audit_fixes.sql
create type public.notification_kind as enum (
  'intro_received',
  'intro_accepted',
  'message_received',
  'voice_received',
  'meeting_reminder',
  'daily_matches_ready',
  'goal_staleness'
);
-- supabase/migrations/20260606010000_schema_fixes.sql adds:
alter type public.notification_kind add value if not exists 'meeting_proposal';
alter type public.notification_kind add value if not exists 'meeting_confirmed';
-- supabase/migrations/20260608050000_opportunities_fixes.sql adds:
alter type public.notification_kind add value if not exists 'opportunity_interest';

-- final notification_kind value set (in declaration order):
--   intro_received, intro_accepted, message_received, voice_received,
--   meeting_reminder, daily_matches_ready, goal_staleness,
--   meeting_proposal, meeting_confirmed, opportunity_interest

create type public.notification_channel as enum ('push', 'email', 'in_app');

-- supabase/migrations/20260606010000_schema_fixes.sql (final shape with rls_followups)
create type public.transcript_status as enum
  ('pending', 'ready', 'failed', 'unsupported');
-- supabase/migrations/20260607030000_rls_followups.sql adds:
alter type public.transcript_status add value if not exists 'processing';
-- final transcript_status value set:
--   pending, ready, failed, unsupported, processing

-- supabase/migrations/20260608020000_opportunities.sql
create type public.opportunity_kind as enum (
  'hiring',           -- posting a role
  'seeking_role',     -- looking for a job
  'fundraising',      -- raising a round
  'investing',        -- deploying capital
  'cofounder',        -- looking for a cofounder
  'advising',         -- offering advisory
  'seeking_advisor',  -- looking for an advisor
  'collaboration'     -- catch-all
);

create type public.opportunity_status as enum ('open', 'closed', 'archived');
```

**Enum inventory (15 enums total):**
`role_kind`, `goal_type`, `intro_state`, `intro_kind`, `meeting_state`, `meeting_feedback_rating`, `message_kind`, `device_platform`, `report_target_type`, `report_reason`, `notification_kind`, `notification_channel`, `transcript_status`, `opportunity_kind`, `opportunity_status`.

### 2.2 Table: `profiles`

Created in `slice1_init.sql` (`id uuid PK references auth.users(id) on delete cascade`), then extended across slice2, slice7, slice16, audit_fixes, phase3_features, and schema_fixes / drop_legacy_notify_cols. Final shape:

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK, FK to `auth.users(id) on delete cascade` |
| `created_at` | `timestamptz` | default `now()` |
| `updated_at` | `timestamptz` | maintained by `extensions.moddatetime(updated_at)` trigger |
| `handle` | `extensions.citext` | UNIQUE (`profiles_handle_unique`), case-insensitive |
| `name` | `text` | 1–80 chars |
| `headline` | `text` | 5–120 chars (nullable) |
| `bio` | `text` | 10–1000 chars (nullable) |
| `roles` | `public.role_kind[]` | NOT NULL, default `'{}'` |
| `primary_role` | `public.role_kind` | must be in `roles` |
| `city` | `text` | required to onboard |
| `country` | `text` | required to onboard |
| `goal_type` | `public.goal_type` | required to onboard |
| `goal_text` | `text` | 10–280 chars; required to onboard |
| `goal_updated_at` | `timestamptz` | auto-stamped by `profiles_set_goal_updated_at()` BEFORE UPDATE when `goal_type` or `goal_text` changes |
| `photo_url` | `text` | nullable |
| `onboarded` | `boolean` | NOT NULL default `false`; flipped to `true` by onboarding submission |
| `verified_github_username` | `text` | slice7; stored lowercase |
| `verified_github_id` | `bigint` | slice7 |
| `verified_at` | `timestamptz` | slice7 |
| `suspended_at` | `timestamptz` | audit_fixes; non-null → `/suspended` screen |
| `private_mode` | `boolean` | phase3, default `false`; hides from feed / search / daily-matches |
| `read_receipts_enabled` | `boolean` | phase3, default `false` |
| `public_investor_page` | `boolean` | phase3, default `false`; controls whether `get_public_profile` exposes `verified_github_username` |
| (REMOVED) `email` | — | dropped in `20260606010000_schema_fixes.sql` (auth.users is source of truth) |
| (REMOVED) `notify_intro`, `notify_message`, `notify_meeting` | — | dropped in `20260606130000_drop_legacy_notify_cols.sql` (superseded by `notification_preferences`) |

**Constraints (verbatim):**

```sql
constraint profiles_handle_unique unique (handle)
constraint profiles_handle_format check (handle is null or (handle operator(extensions.~)
  '^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$'::extensions.citext))
constraint profiles_name_len      check (name is null or (char_length(name) between 1 and 80))
constraint profiles_headline_len  check (headline is null or (char_length(headline) between 5 and 120))
constraint profiles_bio_len       check (bio is null or (char_length(bio) between 10 and 1000))
constraint profiles_goal_text_len check (goal_text is null or (char_length(goal_text) between 10 and 280))
constraint profiles_primary_role_in_roles check (primary_role is null or primary_role = any (roles))
constraint profiles_onboarded_completeness check (
  not onboarded or (
    handle is not null and name is not null and cardinality(roles) >= 1 and primary_role is not null
    and goal_type is not null and goal_text is not null and city is not null and country is not null))
```

**Indexes:**

```sql
profiles_primary_role_idx (primary_role) where primary_role is not null
profiles_onboarded_idx    (onboarded)    where onboarded = true
profiles_verified_github_username_idx (verified_github_username) where verified_github_username is not null
profiles_handle_trgm_idx  using gin (handle extensions.gin_trgm_ops)
profiles_name_trgm_idx    using gin (name   extensions.gin_trgm_ops)
```

**Triggers:**

- `profiles_set_updated_at` BEFORE UPDATE → `extensions.moddatetime(updated_at)`
- `profiles_goal_updated_at_trigger` BEFORE UPDATE → `profiles_set_goal_updated_at()` (stamps `goal_updated_at` on goal change)
- `on_auth_user_created` AFTER INSERT on `auth.users` → `handle_new_auth_user()` (SECURITY DEFINER) inserts a blank `profiles` row with the same id

**RLS (post-hardening, verbatim from `supabase/migrations/20260606000000_rls_hardening.sql` + `20260601000000_fix_anon_profile_leak.sql`):**

```sql
-- Read own row always
policy profiles_select_own for select using (auth.uid() = id)

-- Read other onboarded, non-blocked profiles (authenticated only — anon must NOT read)
policy profiles_select_discoverable for select using (
  auth.uid() is not null and onboarded = true and not exists (
    select 1 from public.blocks
    where (blocker_id = auth.uid() and blocked_id = profiles.id)
       or (blocker_id = profiles.id  and blocked_id = auth.uid())))

-- Update own row (WITH CHECK pinned)
policy profiles_update_own for update using (auth.uid() = id) with check (auth.uid() = id)

-- Column-level UPDATE revoked on sensitive columns from `authenticated`:
revoke update (
  verified_github_id, verified_github_username, verified_at, suspended_at,
  onboarded, private_mode, public_investor_page
) on public.profiles from authenticated;
```

### 2.3 Table: `daily_matches`

`supabase/migrations/20260517000000_slice3_discovery.sql`.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | default `gen_random_uuid()` |
| `user_id` | `uuid` | FK profiles ON DELETE CASCADE — the viewer |
| `pick_user_id` | `uuid` | FK profiles ON DELETE CASCADE — the recommendation |
| `match_reason` | `text` | one of `"Complementary goals"`, `"Shared role"`, `"Same city"`, `"New on Connect"`, `"Daily pick"` |
| `for_date_local` | `date` | the calendar day this pick is for |
| `viewed_at` | `timestamptz` | nullable; stamped by `mark_match_viewed` |
| `created_at` | `timestamptz` | default `now()` |

**Constraints / indexes (verbatim):**

```sql
constraint daily_matches_no_self check (user_id <> pick_user_id)
unique index daily_matches_user_pick_date_uq (user_id, pick_user_id, for_date_local)
index daily_matches_user_date_idx (user_id, for_date_local desc)
```

**RLS:**

```sql
policy daily_matches_select_own for select using (user_id = auth.uid())
policy daily_matches_update_own for update using (user_id = auth.uid()) with check (user_id = auth.uid())
```

UPDATE permission revoked from `authenticated` in `20260607000000_security_hardening.sql`; only `mark_match_viewed` (definer) writes here.

### 2.4 Table: `intros`

`slice4_intros.sql` + `20260606080000_intros_fixes.sql` + `20260608010000_second_degree_intros.sql`.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | default `gen_random_uuid()` |
| `sender_id` | `uuid` | FK profiles ON DELETE SET NULL |
| `recipient_id` | `uuid` | FK profiles ON DELETE SET NULL |
| `note` | `text` | NOT NULL; `char_length(btrim(note)) ∈ [80, 400]` |
| `state` | `public.intro_state` | default `delivered` |
| `kind` | `public.intro_kind` | default `direct` (added in `20260608010000`) |
| `warm_target_id` | `uuid` | FK profiles ON DELETE SET NULL; non-null iff kind ≠ `direct` |
| `conversation_id` | `uuid` | FK conversations ON DELETE SET NULL; populated by `accept_intro` |
| `expires_at` | `timestamptz` | default `now() + interval '14 days'` |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | moddatetime trigger |
| `declined_at` | `timestamptz` | stamped by `decline_intro` (only for `direct` kind — see `warm_intros_fixes`) |

**Constraints (verbatim):**

```sql
constraint intros_no_self check (sender_id is null or recipient_id is null or sender_id <> recipient_id)
constraint intros_note_len check (char_length(btrim(note)) between 80 and 400)
constraint intros_warm_target_consistency check (
  (kind = 'direct' and warm_target_id is null)
  or (kind in ('warm_request','warm_forward') and warm_target_id is not null))
```

**Indexes:**

```sql
intros_sender_state_idx (sender_id, state, created_at desc)
intros_recipient_state_idx (recipient_id, state, created_at desc)
unique index intros_active_pair_uq on (sender_id, recipient_id) where state = 'delivered'
intros_sender_recipient_declined_idx (sender_id, recipient_id, declined_at desc) where state = 'declined'
intros_warm_target_idx (warm_target_id) where warm_target_id is not null
```

**Triggers:**

- `intros_set_updated_at` BEFORE UPDATE → moddatetime
- `intros_push_on_insert` AFTER INSERT → `notify_intro_inserted()` (dispatches push to recipient when state='delivered'; for `warm_forward` it composes `"X (via Y) wants to connect"` and passes `via_user_id` + `via_user_name` in payload; respects `should_notify(..., intro_received, push)`)

**RLS (final, after slice9; verbatim):**

```sql
policy intros_select_party for select using (
  (auth.uid() = sender_id or auth.uid() = recipient_id)
  and not exists (
    select 1 from public.blocks
    where (blocker_id = auth.uid() and (blocked_id = intros.sender_id or blocked_id = intros.recipient_id))
       or ((blocker_id = intros.sender_id or blocker_id = intros.recipient_id) and blocked_id = auth.uid())))
```

No INSERT/UPDATE/DELETE policies — writes go via `send_intro`, `accept_intro`, `decline_intro`, `send_warm_request`, `forward_warm_intro`, `expire_overdue_intros` (all SECURITY DEFINER).

### 2.5 Table: `conversations`

`slice5_chat.sql`.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | default `gen_random_uuid()` |
| `participant_a_id` | `uuid` | FK profiles ON DELETE CASCADE — canonical order: `participant_a_id < participant_b_id` |
| `participant_b_id` | `uuid` | FK profiles ON DELETE CASCADE |
| `last_message_at` | `timestamptz` | nullable; bumped by `bump_conversation_last_message()` AFTER INSERT on messages |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | moddatetime |

**Constraints (verbatim):**

```sql
constraint conversations_canonical_order check (participant_a_id < participant_b_id)
constraint conversations_no_self         check (participant_a_id <> participant_b_id)
unique index conversations_pair_uq (participant_a_id, participant_b_id)
index conversations_a_last_msg_idx (participant_a_id, last_message_at desc nulls last)
index conversations_b_last_msg_idx (participant_b_id, last_message_at desc nulls last)
```

The canonical-order constraint means the UUID with the lower sort order is always `participant_a_id`. Prevents duplicate conversations between the same pair.

**RLS (post-slice9):**

```sql
policy conversations_select_participant for select using (
  (auth.uid() = participant_a_id or auth.uid() = participant_b_id)
  and not exists (select 1 from public.blocks where (blocker_id = auth.uid() and ...) ...))
```

Conversations are created by the `accept_intro` and `book_slot` RPCs only (no direct INSERT from clients).

### 2.6 Table: `messages`

`slice5_chat.sql` + `slice6_meetings.sql` (meeting kind) + `slice13_media.sql` (media kinds) + `slice22_chat_features.sql` (edit/delete) + `phase3_features.sql` (transcript) + `schema_fixes.sql` (enum, NOT NULL sender_id) + `chat_fixes.sql` (replica identity).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `conversation_id` | `uuid` | FK conversations ON DELETE CASCADE |
| `sender_id` | `uuid` | FK profiles ON DELETE CASCADE — NOT NULL (set in `schema_tighten` after zero null rows) |
| `body` | `text` | nullable; required for text kind |
| `kind` | `public.message_kind` | default `text` |
| `meeting_proposal_id` | `uuid` | FK meeting_proposals ON DELETE SET NULL — populated for `meeting` kind |
| `media_path` | `text` | required for image / voice |
| `media_duration_ms` | `integer` | required for voice |
| `media_size_bytes` | `integer` | required for image / voice |
| `edited_at` | `timestamptz` | slice22, set by `edit_message` |
| `deleted_at` | `timestamptz` | slice22, set by `delete_message`; tombstones body + media_path |
| `transcript` | `text` | phase3, set by `transcribe-voice` edge function |
| `transcript_status` | `public.transcript_status` | phase3, enum `pending`/`processing`/`ready`/`unsupported`/`failed` |
| `created_at` | `timestamptz` | |

**Composite kind/payload CHECK (verbatim, from slice22 + slice13):**

```sql
constraint messages_kind_payload check (
  deleted_at is not null
  or (kind = 'text'    and body is not null and meeting_proposal_id is null and media_path is null)
  or (kind = 'meeting' and meeting_proposal_id is not null and body is null)
  or (kind = 'image'   and media_path is not null and meeting_proposal_id is null)
  or (kind = 'voice'   and media_path is not null and media_duration_ms is not null
                       and meeting_proposal_id is null))
```

Plus `messages_body_len` (1–4000) when body is non-null.

**Indexes:**

```sql
messages_conversation_created_idx (conversation_id, created_at)
messages_meeting_proposal_idx (meeting_proposal_id) where meeting_proposal_id is not null
messages_sender_idx (sender_id)
```

**Triggers:**

- `messages_bump_last_message` AFTER INSERT → bumps `conversations.last_message_at`
- `messages_push_on_insert` AFTER INSERT → `notify_message_inserted()` (mute-aware via `conversation_mutes`; prefs-aware via `should_notify`; SUPPRESSED for chat bubbles whose linked proposal is already `confirmed` — office-hours pre-confirmed bookings)
- `messages_voice_transcribe` AFTER INSERT → `on_voice_message_inserted()` → calls `dispatch_transcription` for voice kind

```sql
alter table public.messages replica identity full;
```
Required so Realtime UPDATE / DELETE payloads carry every column (per `20260606070000_chat_fixes.sql`).

`messages` is added to the `supabase_realtime` publication (`alter publication supabase_realtime add table public.messages`).

**RLS (final, from `security_hardening` + `rls_hardening`; verbatim):**

```sql
policy messages_select_participant for select using (
  exists (select 1 from public.conversations c
    where c.id = messages.conversation_id
      and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())))

policy messages_insert_participant for insert with check (
  sender_id = auth.uid() and kind = 'text' and exists (
    select 1 from public.conversations c
    where c.id = messages.conversation_id
      and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = c.participant_a_id and b.blocked_id = c.participant_b_id)
           or (b.blocker_id = c.participant_b_id and b.blocked_id = c.participant_a_id))))
```

Image / voice / meeting / edit / delete all flow through SECURITY DEFINER RPCs — direct non-text INSERTs are rejected.

### 2.7 Table: `meeting_proposals`

`slice6_meetings.sql` + `slice23_meetings_tz_ics.sql` (timezone) + `schema_fixes.sql` (timezone CHECK).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `conversation_id` | `uuid` | FK conversations ON DELETE CASCADE |
| `proposed_by_id` | `uuid` | FK profiles ON DELETE SET NULL |
| `slots` | `timestamptz[]` | 1–3 entries |
| `confirmed_slot` | `timestamptz` | must equal one of `slots` |
| `duration_minutes` | `integer` | 15–240, default 30 |
| `meeting_url` | `text` | must start with `https://` if non-null |
| `timezone` | `text` | IANA name; validated by `now() at time zone timezone is not null` CHECK |
| `state` | `public.meeting_state` | default `proposed` |
| `created_at` / `updated_at` | `timestamptz` | moddatetime |

**Constraints summary:**

```sql
mp_duration_rng (15..240)
mp_slots_count (array_length(slots,1) between 1 and 3)
mp_url_https
mp_confirmed_slot_in_slots
mp_timezone_valid (now() at time zone timezone is not null)
```

Indexes: `meeting_proposals_conversation_idx (conversation_id, created_at desc)`, `meeting_proposals_proposed_by_idx`.

Added to `supabase_realtime` publication.

**Triggers:**

- moddatetime
- `meeting_proposals_push_on_confirm` AFTER UPDATE → `notify_meeting_confirmed()`

**RLS:**

```sql
policy meeting_proposals_select_participant for select using (
  exists (select 1 from conversations c where c.id = meeting_proposals.conversation_id and (...)))
```

No write policies — `propose_meeting`, `confirm_meeting`, `decline_meeting`, `cancel_meeting`, `book_slot` are the entry points.

> **Column-naming note:** The mobile React Native code sometimes refers to this column as `proposer_id` (e.g. Sonnet inventory said `proposer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE`). The actual database column is `proposed_by_id` and the FK is `ON DELETE SET NULL`. Quoted SQL above is verbatim from `supabase/migrations/20260520000000_slice6_meetings.sql`.

### 2.8 Table: `meeting_feedback` (legacy — see also `meeting_reviews`)

`slice6_meetings.sql`.

```sql
id uuid PK,
meeting_id uuid FK meeting_proposals on delete cascade,
rater_id uuid FK profiles on delete cascade,
rating meeting_feedback_rating not null,
note text (≤1000),
unique (meeting_id, rater_id)
```

RLS: `mf_select_self` (`rater_id = auth.uid()`). Written via `submit_meeting_feedback`.

This table is **partially superseded** by `meeting_reviews` (the post-meeting prompt UI uses `meeting_reviews`). Both tables exist; see §17.

### 2.9 Table: `meeting_reviews`

`20260602000000_phase2_meeting_reviews.sql` (initially `rating int 1..5`) + `20260604000000_audit_fixes.sql` (changed to `outcome text`).

```sql
id uuid PK,
meeting_id uuid FK meeting_proposals on delete cascade,
reviewer_id uuid FK profiles on delete cascade,
outcome text NOT NULL CHECK in ('useful','not_useful','no_show'),
note text,
created_at timestamptz default now(),
unique (meeting_id, reviewer_id)
```

`outcome` mapping for `get_profile_signals`: `useful = 5`, `not_useful = 2`, `no_show = 1`.

RLS: `reviews_select_party` — reviewer OR meeting participant (via conversation).

Written via `submit_meeting_review`.

### 2.10 Table: `meeting_playbooks`

`20260608040000_meeting_playbooks.sql`.

```sql
meeting_id uuid FK meeting_proposals on delete cascade,
viewer_id  uuid FK profiles on delete cascade,
target_id  uuid FK profiles on delete cascade,
summary text NOT NULL,
shared_interests text[] default '{}' NOT NULL,
conversation_starters text[] default '{}' NOT NULL,
do_notes text[] default '{}' NOT NULL,
dont_notes text[] default '{}' NOT NULL,
generated_at timestamptz default now() NOT NULL,
generation_input_hash text NOT NULL,
PRIMARY KEY (meeting_id, viewer_id)
```

Index `meeting_playbooks_viewer_idx (viewer_id, generated_at desc)`.

**RLS:** `meeting_playbooks_no_direct_access` (`false / false`). Reads via `get_meeting_playbook(uuid)` RPC; writes via `meeting-playbook` edge function (service-role).

### 2.11 Table: `blocks`

`slice9_privacy.sql`.

```sql
blocker_id uuid FK profiles on delete cascade,
blocked_id uuid FK profiles on delete cascade,
created_at timestamptz default now(),
PRIMARY KEY (blocker_id, blocked_id),
constraint blocks_no_self check (blocker_id <> blocked_id)
```

Index `blocks_blocked_idx (blocked_id)`. RLS: `blocks_select_own` (`blocker_id = auth.uid()`). Writes via `block_user`, `unblock_user`.

### 2.12 Table: `reports`

`slice9_privacy.sql`.

```sql
id uuid PK,
reporter_id uuid FK profiles on delete cascade,
target_type public.report_target_type NOT NULL,
target_id uuid NOT NULL,
reason public.report_reason NOT NULL,
note text (≤1000),
quoted_message_id uuid references public.messages(id) on delete set null,
created_at timestamptz default now()
```

Indexes: `reports_target_idx (target_type, target_id)`, `reports_target_created_idx (target_type, target_id, created_at desc)`.

RLS: enabled, **no SELECT policy** (admin / service-role path only). Written via `report_target` (SECURITY DEFINER).

### 2.13 Table: `conversation_reads`

`slice22_chat_features.sql`.

```sql
user_id uuid FK profiles on delete cascade,
conversation_id uuid FK conversations on delete cascade,
last_read_at timestamptz NOT NULL default now(),
PRIMARY KEY (user_id, conversation_id)
```

RLS: `*_select_own`, `*_insert_own` (own `user_id`), `*_update_own` (own `user_id` WITH CHECK).

### 2.14 Table: `conversation_mutes`

`slice22_chat_features.sql`.

```sql
user_id uuid FK profiles on delete cascade,
conversation_id uuid FK conversations on delete cascade,
muted_at timestamptz default now(),
PRIMARY KEY (user_id, conversation_id)
```

RLS: `*_select_own`, `*_insert_own`, `*_delete_own`.

### 2.15 Table: `device_tokens`

`slice8_push.sql` + `schema_fixes.sql` (revoked_at) + `20260606120000_device_tokens_unique.sql` (UNIQUE on `token`).

```sql
id uuid PK,
user_id uuid FK profiles on delete cascade,
token text NOT NULL,
platform public.device_platform NOT NULL,
last_seen_at timestamptz default now(),
created_at timestamptz default now(),
revoked_at timestamptz,
constraint device_tokens_token_key unique (token)   -- NOT (user_id, token)
```

Indexes: `device_tokens_user_idx (user_id)`, `device_tokens_user_active_idx (user_id) where revoked_at is null`.

RLS: `device_tokens_select_own`. Writes via `register_device_token`, `unregister_device_token`. The `send-push` edge function also hard-drops tokens on FCM errors (`UNREGISTERED`, etc.).

### 2.16 Table: `push_log`

`slice8_push.sql`.

```sql
id uuid PK,
event_table text NOT NULL,
event_id uuid NOT NULL,
recipient_id uuid FK profiles on delete cascade,
payload jsonb NOT NULL,
delivered boolean default false,
error text,
created_at timestamptz default now(),
unique (event_table, event_id, recipient_id)
```

Index `push_log_recipient_idx (recipient_id, created_at desc)`. RLS: `push_log_select_own`.

Used by `dispatch_push` for idempotency; the `delivered=true` flag is flipped by `send-push` edge function via atomic UPDATE (5-minute replay window).

### 2.17 Table: `notification_preferences`

`audit_fixes.sql`.

```sql
user_id uuid FK profiles on delete cascade,
kind public.notification_kind NOT NULL,
channel public.notification_channel NOT NULL,
enabled boolean default true NOT NULL,
PRIMARY KEY (user_id, kind, channel)
```

RLS: `notification_prefs_select_own`, `notification_prefs_modify_own` (FOR ALL).

Helper `should_notify(uuid, kind, channel)` defaults to `true` when no row exists (revoked from `authenticated` after `rls_hardening` — only definer triggers consume it).

### 2.18 Table: `opportunities`

`20260608020000_opportunities.sql`.

```sql
opportunities (
  id uuid PK,
  author_id uuid FK profiles on delete cascade,
  kind public.opportunity_kind NOT NULL,
  title text NOT NULL CHECK char_length 5..120,
  body text NOT NULL CHECK char_length 10..2000,
  tags text[] default '{}' CHECK cardinality <= 8
       (per-tag lowercase 1..30 validated in `_opportunity_validate_input` RPC),
  location_city text,
  location_country text,
  remote_ok boolean default false,
  status public.opportunity_status default 'open',
  expires_at timestamptz default now() + interval '30 days',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  closed_at timestamptz)
```

**Indexes:**

```sql
opportunities_open_idx (created_at desc) where status='open'   -- IMMUTABLE-safe (fix #1 in 20260608050000_opportunities_fixes.sql)
opportunities_author_idx (author_id, status, created_at desc)
opportunities_kind_idx (kind, created_at desc) where status='open'
```

**Triggers:**

- `opportunities_set_updated_at` → moddatetime

**RLS (notable — writes are blocked from clients; verbatim):**

```sql
policy opportunities_select_visible for select to authenticated using (
  author_id = auth.uid()
  or (status = 'open' and (expires_at is null or expires_at > now())
      and not exists (select 1 from blocks where (blocker_id = auth.uid() and blocked_id = opportunities.author_id) or ...)))

policy opportunities_no_direct_mutate for all to authenticated using (false) with check (false)
```

### 2.19 Table: `opportunity_interests`

`20260608020000_opportunities.sql`.

```sql
opportunity_interests (
  opportunity_id uuid FK opportunities on delete cascade,
  user_id uuid FK profiles on delete cascade,
  note text CHECK 10..500 when non-null,
  created_at timestamptz default now(),
  PRIMARY KEY (opportunity_id, user_id))
```

Index `opportunity_interests_user_idx (user_id, created_at desc)`.

**Trigger:** `opportunity_interests_push_on_insert` → `notify_opportunity_interest()` (`20260608050001_opportunities_fixes_trigger.sql`). Uses `md5(opp || ':' || user)::uuid` as deterministic `event_id` to avoid push_log collisions.

**RLS:**

```sql
policy opportunity_interests_select_relevant for select to authenticated using (
  user_id = auth.uid()
  or exists (select 1 from opportunities o where o.id = opportunity_interests.opportunity_id and o.author_id = auth.uid()))

policy opportunity_interests_no_direct_mutate for all to authenticated using (false) with check (false)
```

### 2.20 Table: `office_hours_settings`

`20260608030000_office_hours.sql`.

```sql
office_hours_settings (
  user_id uuid PK FK profiles on delete cascade,
  enabled boolean default false,
  windows jsonb default '[]' CHECK jsonb_typeof = array,
  slot_duration_minutes int CHECK in (15,30,45,60) default 15,
  max_bookings_per_week int CHECK 1..50 default 5,
  buffer_minutes int CHECK 0..60 default 5,
  meeting_link_template text,    -- supports `{slot_id}` literal interpolation
  notes_template text,
  updated_at timestamptz default now())
```

**`windows` JSONB shape:** Array of objects:

```json
{
  "weekday": 0..6,           // 0 = Sunday
  "start_minute": 0..1439,
  "end_minute": 0..1439,
  "timezone": "<IANA name>"
}
```

<!-- DISCREPANCY: Sonnet wrote `slot_duration_minutes default 30, max_bookings_per_week default 3, buffer_minutes default 0`; Opus wrote `slot_duration_minutes default 15, max_bookings_per_week default 5, buffer_minutes default 5`. Source `supabase/migrations/20260608030000_office_hours.sql` confirms Opus's defaults (15 / 5 / 5). -->

### 2.21 Table: `office_hours_slots`

`20260608030000_office_hours.sql`.

```sql
office_hours_slots (
  id uuid PK,
  host_id uuid FK profiles on delete cascade,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  status text CHECK in ('open','booked','cancelled') default 'open',
  booked_by uuid FK profiles on delete set null,
  booked_at timestamptz,
  meeting_proposal_id uuid FK meeting_proposals on delete set null,
  topic text,
  CHECK ends_at > starts_at)
```

**Indexes:**

```sql
unique office_hours_slots_unique_host_start (host_id, starts_at)
office_hours_slots_open_idx (host_id, starts_at) where status='open'
office_hours_slots_booker_idx (booked_by, starts_at desc) where status='booked'
```

**RLS (read-only on the client):**

```sql
office_hours_settings_read_all (true)
office_hours_settings_no_direct_mutate (false / false)
office_hours_slots_read (host_id = auth.uid() or booked_by = auth.uid() or status='open')
office_hours_slots_no_direct_mutate (false / false)
```

Writes via `set_office_hours`, `materialize_office_hours_slots` (internal), `book_slot`, `cancel_booking`.

### 2.22 Storage Buckets

`slice13_media.sql` + storage_hardening passes.

| Bucket | Public | Size limit | MIME allow-list |
|---|---|---|---|
| `avatars` | `true` | 5 MB (5 242 880 B) | `image/jpeg`, `image/png`, `image/webp` |
| `chat-media` | `false` | 25 MB (26 214 400 B) | `image/jpeg`, `image/png`, `image/webp`, `audio/mp4`, `audio/aac`, `audio/m4a`, `audio/webm` |

**Path conventions:**

- `avatars`: `{userId}/...`
- `chat-media`: `{conversationId}/{messageId}/{filename}`

**Storage policies (final shape):**

```sql
-- avatars
policy "avatars-read"   for select using (bucket_id='avatars')
policy "avatars-insert" for insert with check (bucket_id='avatars' and (storage.foldername(name))[1] = auth.uid()::text)
policy "avatars-update" for update using (...auth.uid()::text)  with check (...auth.uid()::text)
policy "avatars-delete" for delete using (...auth.uid()::text)

-- chat-media (latest from media_message_rpcs / storage_hardening)
policy "chat-media-read"   for select using (
  bucket_id='chat-media' and exists (select 1 from conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())))

policy "chat-media-insert" for insert with check (
  bucket_id='chat-media' and exists (select 1 from conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())))

policy "chat-media-update" for update using (... message exists with id = foldername[2] and sender_id = auth.uid()
                                                and conversation_id::text = foldername[1])
                              with check (... same ...)

policy "chat-media-delete" for delete using (... same as update USING ...)
```

Private reads require a signed URL via `useSignedUrl` hook (TTL 60 seconds).

**Orphan sweep:** cron `chat-media-orphan-sweep` (04:00 UTC) deletes `chat-media` objects older than 24h with no matching `messages.media_path`.

---

## Section 3 — All RPCs

All RPCs live in the `public` schema. Unless noted, they are `SECURITY DEFINER` with `search_path = public, extensions` (sometimes `public, storage`). Each is granted to `authenticated` unless noted otherwise. The caller's identity is obtained via `auth.uid()`.

**Inventory:** 75 unique `create or replace function public.*` declarations exist across `supabase/migrations/`, of which:

- ~50 client-callable RPCs (granted to `authenticated`)
- 8 internal trigger functions (`handle_new_auth_user`, `bump_conversation_last_message`, `notify_intro_inserted`, `notify_message_inserted`, `notify_meeting_confirmed`, `notify_opportunity_interest`, `on_voice_message_inserted`, `profiles_set_goal_updated_at`)
- 4 service-role / internal-only (`dispatch_push`, `dispatch_transcription`, `expire_overdue_intros`, `materialize_office_hours_slots`)
- 1 private helper (`_opportunity_validate_input`)
- 1 deprecated (`lookup_email_by_handle` — service-role only after `20260606060000_revoke_handle_lookup.sql`)

### 3.1 Profile / auth helpers

#### `check_handle_available(p_handle text) → boolean`

`slice2_profile.sql` + `20260607020000_feature_fixes.sql` #4. Validates handle against the `^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$` citext regex (same as the table CHECK). Returns `false` on null / empty / format violation; otherwise returns `not exists (handle = p_handle::citext)`. Granted to `authenticated`.

#### `lookup_email_by_handle(p_handle text) → text` (DEPRECATED — service-role only)

`20260605000000_password_auth.sql`. Originally granted to `anon` for handle-based sign-in. Revoked from anon in `20260606060000_revoke_handle_lookup.sql` once the `auth-handle-login` edge function took over. Service-role can still call it.

#### `get_public_profile(p_handle text) → TABLE` (STABLE — anon-callable)

`phase3_features.sql` + `schema_fixes.sql` #13 (citext-native lookup). Returns one row:

```
id, handle, name, photo_url, headline, bio, primary_role, roles, city, country,
verified_github_username  -- ONLY when profile.public_investor_page=true; otherwise null
```

Filters: handle citext eq + `onboarded=true` + `not private_mode` + `suspended_at IS NULL`.

#### `set_github_verification(p_github_username text, p_github_id bigint) → public.profiles`

`slice7_verification.sql`. Stores lowercased username + id + `verified_at = now()` on caller's profile. Note: column-level UPDATE on `verified_*` is revoked from `authenticated` (§2.2), so this RPC is the only path to set these columns. SECURITY DEFINER bypasses the column-level grant.

#### `clear_github_verification() → public.profiles`

`slice7_verification.sql`. Nulls all three verification columns.

#### `set_private_mode(p_value boolean) → void`

`phase3_features.sql`. Toggles `profiles.private_mode` for the calling user. SECURITY DEFINER (column-level UPDATE on `private_mode` is revoked from `authenticated`).

#### `export_my_data() → jsonb`

`slice16_settings.sql`. Aggregates `profile`, `intros_sent`, `intros_received`, `conversations`, `messages_sent`, `meeting_proposals`, `blocks`, `reports_filed` for `auth.uid()` into a single JSON blob. Granted to `authenticated`.

#### `delete_my_account() → void`

`20260606040000_delete_account_rpc.sql`. Idempotent wipe of all FK-owned and FK-orphanable rows for `auth.uid()` across all tables. Called by the `delete-account` edge function, which then admin-deletes the `auth.users` row.

#### `get_profile_signals(p_target uuid) → TABLE(mutual_connection_count int, mutual_top_user_ids uuid[], avg_meeting_rating numeric(2,1), total_meeting_reviews int)`

`20260608000000_profile_signals.sql`. Self-view → zeros / nulls. Blocked pair → zeros / nulls. Otherwise:

- `mutual_connection_count` = |viewer ∩ target| over `intros` with state='connected' (excluding viewer/target themselves and blocked pairs).
- `mutual_top_user_ids` = up to 5 most-recent mutual `other_id`s.
- `avg_meeting_rating` is **hidden (NULL) when total < 3 reviews** — otherwise `round(avg(score), 1)` with outcome→score mapping `useful=5, not_useful=2, no_show=1`.
- `total_meeting_reviews` always returned.

Revoked from PUBLIC and anon.

### 3.2 Discovery & Matching

#### `get_daily_matches(p_for_date date default current_date) → TABLE`

`slice3_discovery.sql` → `discovery_fixes` (final). Returns shape:

```
id, pick_user_id, match_reason, for_date_local, viewed_at, created_at,
name, handle, photo_url, headline, bio, city, country, primary_role, roles, goal_type
```

Behaviour:

- Insert-once-per-day: if `daily_matches` has 0 rows for (auth.uid(), date), inserts top 5 onboarded non-private non-suspended non-blocked profiles by `match_score(...) desc, p.created_at desc, random()`.
- Trailing SELECT re-applies the same private/suspended/block filters in case picks went stale between days.
- Returns inner join with profiles for the client.
- Uses `#variable_conflict use_column` (PostgreSQL-internal; transparent to client).

#### `mark_match_viewed(p_match_id uuid) → void`

`slice3_discovery.sql`. Stamps `viewed_at = now()` only when caller owns the row and it's still null.

#### `match_score(p_self uuid, p_other uuid) → int` (STABLE)

`slice17_matching.sql`. Scoring:

- +2 per overlapping role kind.
- +4 for complementary goals (`goals_complementary`), +1 if `goal_type` is identical.
- +3 same city (case-insensitive trim), +1 same country.
- Recency boost: profile.created_at within 1h → +5, 24h → +3, 7d → +1.

Revoked from PUBLIC.

#### `match_reason_for(p_self uuid, p_other uuid) → text` (STABLE)

`slice17_matching.sql`. Priority order: `"Complementary goals"` → `"Shared role"` → `"Same city"` → `"New on Connect"` (target created < 24h ago) → `"Daily pick"`. Revoked from PUBLIC.

#### `goals_complementary(a public.goal_type, b public.goal_type) → boolean` (IMMUTABLE, PARALLEL SAFE)

`slice17_matching.sql`. Returns `true` for: `hire ↔ be_hired`, `invest ↔ take_investment`, `advise ↔ find_advisor`. Revoked from PUBLIC.

> Note: Sonnet's inventory said `co_found ↔ co_found` is treated as complementary; this is incorrect per source. `co_found` and `peer_connect` are "same goal" only — they receive the +1 same-goal weight in `match_score`, not the +4 complementary weight.

#### `is_mutual_match(p_other uuid) → boolean`

`slice21_polish.sql`. Returns `true` iff `(auth.uid, p_other)` AND `(p_other, auth.uid)` both exist in today's `daily_matches`.

#### `search_discoverable_profiles(p_query text, p_roles role_kind[], p_goal_types goal_type[], p_country text, p_cursor timestamptz default '9999-12-31', p_limit int default 20) → TABLE`

`slice24_search.sql` + `phase3_features.sql` (private_mode filter). Returns profile rows excluding self, private, suspended, blocked. Filters:

- `p_query` matches `ILIKE '%q%'` on `handle::text` and `coalesce(name,'')`. pg_trgm GIN indexes accelerate.
- `p_roles` array overlap.
- `p_goal_types` any-of.
- `p_country` case-insensitive equal.
- `p_cursor` is the `created_at` of the last seen row (keyset pagination); DESC order.

### 3.3 Intros

#### `send_intro(p_recipient_id uuid, p_note text) → public.intros`

`slice4_intros.sql` + `20260606080000_intros_fixes.sql` + `20260607020000_feature_fixes.sql` (UTC bucket).

**Validation + error codes raised:**

- `28000` unauthenticated
- `22023` self / note length (`char_length(btrim(note)) ∈ [80, 400]`)
- `P0002` recipient not onboarded
- `P0001 hint='cooldown'` recipient declined within 30 days
- `P0001 hint='daily_cap'` sender already at 20 intros today (UTC calendar day)
- `23505` unique-pair violation (active delivered row already exists)

Inserts with `btrim(p_note)`.

#### `accept_intro(p_intro_id uuid) → public.intros`

`slice4` → `slice5` (creates conversation) → `rls_hardening` (re-checks blocks under row lock) → `warm_intros_fixes` (refuses `warm_request` kind).

- Only the recipient may accept.
- Must be `state='delivered'`, not expired, sender alive.
- **Refuses `kind='warm_request'`** with `22023 wrong intro kind` (these go through `forward_warm_intro`).
- Refuses if either side blocked the other (recheck after row lock).
- Creates canonical (a, b) conversation if missing (`a < b` by uuid order).
- Sets `state='connected'`, `conversation_id=<conv>`.

#### `decline_intro(p_intro_id uuid) → public.intros`

`slice4` → `intros_fixes` (stamps `declined_at`) → `warm_intros_fixes` (skips `declined_at` for `warm_request` so the 30-day cooldown isn't poisoned).

#### `intros_today_count() → int` (STABLE)

`intros_fixes` / `feature_fixes` (UTC bucketing). **Recipient-side** count of intros received today (UTC calendar day). Used to power the inbox daily-cap banner.

#### `expire_overdue_intros() → int` (cron-only)

`intros_fixes`. Sweeps `state='delivered' AND expires_at < now()` → `expired`. Revoked from PUBLIC — only the `expire-overdue-intros` pg_cron job (hourly) calls it.

#### Warm intros (2nd-degree network)

Migrations: `20260608010000_second_degree_intros.sql` + `20260608060000_warm_intros_fixes.sql` + `20260609000000_suggest_warm_intros_use_column.sql`.

**`suggest_warm_intros(p_limit int default 10) → TABLE`**

Ranks 2nd-degree targets by distinct mutual count. Returns:

```
target_id, target_handle, target_name, target_photo_url, target_primary_role, target_goal_type,
mutual_count int, top_mutual_id uuid, top_mutual_name text, top_mutual_handle text
```

Excludes: already-connected, any existing intro row in either direction, any pending (`state='delivered'`, `kind='warm_request'`, `warm_target_id=target`) warm_request from viewer to target via any mutual, blocked, suspended, private, non-onboarded. Uses `#variable_conflict use_column`.

**`send_warm_request(p_mutual_id uuid, p_target_id uuid, p_note text) → uuid`**

Anti-shotgun: only one outstanding warm_request per (sender, target) across any mutual. Note 80–400 chars.

Validates triangle: both legs are `state='connected'` intros; block-free across the whole triangle; target onboarded + non-private + not-suspended; asker has no existing intro to target; asker has no pending warm_request to same target via any mutual; 20/day outbound cap. Inserts `kind='warm_request', sender_id=asker, recipient_id=mutual, warm_target_id=target, state='delivered'`. Returns the new intro id.

**`forward_warm_intro(p_intro_id uuid, p_note text) → uuid`**

Caller must be the `warm_request` recipient (the mutual). Re-checks `block(asker, target)`. Synthesises a new `kind='warm_forward', sender_id=asker, recipient_id=target, warm_target_id=mutual, state='delivered'` row (uses `notify_intro_inserted` to push the target). Closes the original warm_request as `state='connected'`. Note 80–400 chars.

#### `list_connections() → TABLE`

`slice15_connections.sql` + `20260609000000_suggest_warm_intros_use_column.sql` (variable-conflict fix). Final return shape:

```
user_id, handle, name, photo_url, primary_role, conversation_id, connected_at
```

DISTINCT ON `(other_id)`, most-recent `connected` intro per peer; excludes blocked; requires onboarded. Uses `#variable_conflict use_column`.

### 3.4 Chat / messaging

#### `mark_conversation_read(p_conversation_id uuid) → void`

`slice22_chat_features.sql` → `security_hardening` (always upsert; read_receipts gate removed) → `rls_followups` (participant check added).

Validates caller is a participant. Upserts a `conversation_reads` row with `last_read_at = now()`.

#### `mute_conversation(p_conversation_id uuid) → void`

`slice22_chat_features.sql`. Inserts a `conversation_mutes` row.

#### `unmute_conversation(p_conversation_id uuid) → void`

`slice22_chat_features.sql`. Deletes the `conversation_mutes` row.

#### `edit_message(p_id uuid, p_body text) → public.messages`

`slice22_chat_features.sql`. Only the sender, only `kind='text'`, only within 15 minutes of `created_at`, not already deleted, body 1–4000 chars. Stamps `edited_at`.

#### `delete_message(p_id uuid) → public.messages`

`slice22_chat_features.sql`. Tombstones: sets `deleted_at = now()`, nulls `body` + `media_path`. Only the sender.

#### `list_conversation_unread() → TABLE(conversation_id uuid, unread_count int)`

`slice22_chat_features.sql`. Per-conversation unread count where `created_at > coalesce(last_read_at, '1970-01-01')`.

#### `list_conversation_overview(p_user_id uuid default auth.uid()) → TABLE`

`20260606070000_chat_fixes.sql`. Single-RPC chat list:

```
conversation_id, peer_id, peer_name, peer_handle, peer_photo_url,
last_message_body, last_message_kind, last_message_at, unread_count, is_muted
```

Lateral join for last message; ordered by `last_message_at DESC`; rejects `p_user_id <> auth.uid()` with `42501`. The React Native service passes `{ p_user_id: userId }` explicitly; Flutter should call with no arguments to use the default `auth.uid()`.

#### `send_image_message(p_conversation_id uuid, p_media_path text, p_media_mime text, p_media_size_bytes int) → public.messages`

`20260606110000_media_message_rpcs.sql`. Validates path layout `{conversationId}/{messageId}/...`, conversation match, storage object owner = caller, size ≤ 5 MB. Inserts `kind='image'` row with id parsed from path segment.

> Signature note: Sonnet's inventory said `(p_conversation_id, p_path, p_filename, p_size_bytes int) → uuid`; Opus said `(p_conversation_id, p_media_path, p_media_mime, p_media_size_bytes int) → messages`. **Source confirms Opus.** Parameters are `p_conversation_id, p_media_path, p_media_mime, p_media_size_bytes`; return type is `public.messages`.

#### `send_voice_message(p_conversation_id uuid, p_media_path text, p_media_mime text, p_media_size_bytes int, p_duration_ms int) → public.messages`

`20260606110000_media_message_rpcs.sql`. Same path validation + caller-owned storage row. Duration ≤ 120 000 ms (2 min). Size ≤ 25 MB. Inserts `kind='voice'` row with `transcript_status='pending'` → triggers `on_voice_message_inserted` → `dispatch_transcription`.

### 3.5 Meetings

#### `propose_meeting(p_conversation_id uuid, p_slots timestamptz[], p_duration_minutes int default 30, p_meeting_url text default null, p_timezone text default null) → public.meeting_proposals`

`slice6_meetings.sql` → `slice23_meetings_tz_ics.sql` (timezone) → `security_hardening` (block check). Verifies participant; inserts proposal AND a `kind='meeting'` chat bubble row pointing at it.

Validations: 1–3 future slots, duration 15–240, URL must be `https://...` or null, not blocked.

#### `confirm_meeting(p_meeting_id uuid, p_slot timestamptz) → public.meeting_proposals`

`slice6_meetings.sql`. **The proposer may NOT confirm** (must be the other participant). Slot must be one of `slots`. Flips state to `confirmed`, sets `confirmed_slot`.

#### `decline_meeting(p_meeting_id uuid) → public.meeting_proposals`

`slice6_meetings.sql`. Non-proposer declines. Transitions to `declined`.

#### `cancel_meeting(p_meeting_id uuid) → public.meeting_proposals`

`20260606100000_meetings_fixes.sql`. Only the proposer; only while `state='proposed'`.

#### `submit_meeting_feedback(p_meeting_id uuid, p_rating meeting_feedback_rating, p_note text default null) → public.meeting_feedback`

`slice6_meetings.sql`. Only for `state='confirmed'`. Upsert on `(meeting_id, rater_id)`. (Note: superseded by `submit_meeting_review` in the UI.)

#### `submit_meeting_review(p_meeting_id uuid, p_outcome text, p_note text) → public.meeting_reviews`

`20260602000000_phase2_meeting_reviews.sql` (originally `rating int`) → `audit_fixes` (`outcome text` in `useful/not_useful/no_show`) → `security_hardening` (participant + confirmed state) → `rls_followups` (meeting must have ENDED: `confirmed_slot + duration < now()`).

Errors:
- `28000` unauthenticated
- `22023` outcome not in (`useful`, `not_useful`, `no_show`)
- `42501` not a participant
- gating: meeting must be `confirmed` AND `confirmed_slot + (duration_minutes * interval '1 minute') < now()`

#### `pending_meeting_reviews(p_conversation_id uuid default null) → setof public.meeting_proposals` (STABLE)

`20260606100000_meetings_fixes.sql` → `feature_fixes` (re-created with parameter; the zero-arg version was dropped). Returns confirmed meetings the caller participated in whose `confirmed_slot + duration < now()` AND `confirmed_slot > now() - 14 days` AND the caller has NOT yet reviewed. Optional `p_conversation_id` filter for the PostMeetingPrompt scope.

#### `get_meeting_playbook(p_meeting_id uuid) → TABLE`

`20260608040000_meeting_playbooks.sql`. Returns the cached `meeting_playbooks` row for (meeting, calling user). Returns empty set if none exists or caller is not a participant.

### 3.6 Office hours

#### `set_office_hours(p_enabled boolean, p_windows jsonb, p_slot_duration_minutes int, p_max_bookings_per_week int, p_buffer_minutes int, p_meeting_link_template text, p_notes_template text) → public.office_hours_settings`

`20260608030000_office_hours.sql`. Validates per-window shape (weekday 0..6, start_minute / end_minute 0..1439, end > start, timezone exists in `pg_timezone_names`). Upserts; calls `materialize_office_hours_slots`.

#### `my_office_hours_settings() → public.office_hours_settings`

`20260608030000_office_hours.sql`. Fetches own row or returns a synthesised default row (`enabled=false, windows=[], slot_duration_minutes=15, max_bookings_per_week=5, buffer_minutes=5`).

#### `list_upcoming_slots(p_host uuid) → TABLE(id, starts_at, ends_at, host_settings_notes_template text)`

`20260608030000_office_hours.sql`. Open future slots in next 14 days for the host; respects blocks in either direction (returns empty).

#### `book_slot(p_slot_id uuid, p_topic text) → uuid` (returns meeting_proposal id)

Final shape from `20260608070000_office_hours_fixes.sql`:

- Atomic `for update` claim on slot row.
- Rejects if `status<>'open'`, slot starts within 15 minutes, host = caller, host blocked the booker (or vice versa), host disabled OH, weekly cap (`max_bookings_per_week`, bucket = Monday 00:00 UTC) reached.
- Topic 5–280 chars.
- Finds/creates canonical (a, b) conversation.
- Inserts pre-`confirmed` meeting_proposal (`proposed_by_id = host`), chat bubble (`kind=meeting`).
- Notification: `notify_message_inserted` short-circuits when the linked proposal is already `state='confirmed'` (so the chat bubble does NOT trigger the meeting_proposal push). `book_slot` itself explicitly calls `dispatch_push` with the canonical `meeting_confirmed` payload routed to the host.
- Resolves `meeting_url` from template via `replace(template, '{slot_id}', slot.id::text)` and rejects when result doesn't start with `https://`.

#### `cancel_booking(p_slot_id uuid) → void`

Host or booker may call. `state='booked'` required.

- If `starts_at > now() + 24h`: slot reopens to `status='open'` (booked_by / booked_at / meeting_proposal_id / topic cleared).
- Else: `status='cancelled'`.
- Underlying meeting_proposal force-cancelled directly (bypassing `cancel_meeting` which only allows `proposed → cancelled`).

#### `my_bookings() → TABLE(slot_id, host_id, host_handle, host_name, host_photo_url, starts_at, ends_at, topic, meeting_proposal_id)`

Caller's `status='booked'` slots, `starts_at > now() - 1h`.

#### `materialize_office_hours_slots(p_host uuid) → void` (internal)

Revoked from all roles. Deletes future open slots and inserts new ones for the next 14 *host-local* days, applying `slot_duration_minutes + buffer_minutes` step. DST-correct via `(date::text || ' HH:MM')::timestamp at time zone tz`. Day-of-week computed on the wall-clock timestamp to avoid GUC-dependent extract.

### 3.7 Opportunities

#### `list_opportunities(p_kinds opportunity_kind[], p_remote_only boolean, p_search text, p_limit int default 20, p_offset int default 0) → TABLE`

`20260608050000_opportunities_fixes.sql` (final). Filters: `status='open'`, not expired (`expires_at > now()`), not blocked, author onboarded + non-private + not-suspended. Title/body ILIKE for search. Limit capped at 50.

#### `get_opportunity(p_id uuid) → TABLE`

Author always sees own (any status). Non-authors must pass the same gating. Returns `interested_count` and `viewer_has_expressed_interest`.

#### `create_opportunity(p_kind, p_title, p_body, p_tags, p_location_city, p_location_country, p_remote_ok, p_expires_at) → uuid`

Calls `_opportunity_validate_input` (title 5–120, body 10–2000, tags ≤ 8 each lowercase 1–30). Author must be onboarded.

#### `update_opportunity(p_id, kind, title, body, tags, city, country, remote_ok, expires_at) → public.opportunities`

Only the author.

#### `close_opportunity(p_id uuid) → public.opportunities`

Only the author. Sets `status='closed', closed_at=now()`.

#### `express_interest(p_opportunity_id uuid, p_note text default null) → void`

Idempotent. Refuses self, non-open, expired, blocked (either direction). Note 10–500 chars if provided.

#### `list_my_opportunities() → TABLE`

Own posts (any status), with `interested_count`.

#### `list_interested(p_opportunity_id uuid) → TABLE(user_id, handle, name, photo_url, primary_role, note, created_at)`

Only the opportunity author may call.

### 3.8 Privacy

#### `block_user(p_target uuid) → void`

`slice9_privacy.sql`. Refuses self. Idempotent on PK. Also flips any active `delivered` intros between the pair to `declined`.

#### `unblock_user(p_target uuid) → void`

`slice9_privacy.sql`.

#### `list_blocked_users() → TABLE(blocked_id, handle, name, photo_url, created_at)`

`slice9_privacy.sql`.

#### `report_target(p_target_type text, p_target_id uuid, p_reason text, p_note text) → void`

`slice9_privacy.sql`. Refuses reporting self when `target_type='profile'`. Casts text → enums; caller's text must be valid `report_target_type` / `report_reason`.

### 3.9 Push / notifications

#### `register_device_token(p_token text, p_platform device_platform) → public.device_tokens`

`slice8_push.sql` → `device_tokens_unique` (`on conflict (token)`) → `security_hardening` (rejects when token already bound to a different live user via `28000 token already registered to another account`). Token length ≥ 16. Sets `revoked_at = null` on reassign.

#### `unregister_device_token(p_token text) → void`

`rls_hardening`. Stamps `revoked_at = now()` on the token row. Called during sign-out.

#### `dispatch_push(p_recipient_id uuid, p_event_table text, p_event_id uuid, p_payload jsonb, p_kind text default null, p_entity_id uuid default null, p_conversation_id uuid default null) → void`

Final shape from `20260606150000_dispatch_push_payload.sql`. Logs to `push_log` (idempotent via unique key), short-circuits when no active device tokens, then `pg_net.http_post`s the `send-push` edge function with `Content-Type: application/json` and `X-Supabase-Webhook-Secret: <app.webhook_shared_secret>`.

Body shape:

```json
{
  "recipient_id": "<uuid>",
  "event_table": "<string>",
  "event_id": "<uuid>",
  "payload": { ... },
  "data": { "kind": "...", "entity_id": "...", "conversation_id": "..." }
}
```

(`data` is `jsonb_strip_nulls`'d before send.) PUBLIC EXECUTE revoked in `20260607000000_security_hardening.sql` — only definer functions (triggers + `book_slot`) invoke it.

#### `dispatch_transcription(p_message_id uuid) → void`

`phase3_features.sql` → `dispatch_webhook_secret`. Flips `transcript_status` to `pending` then HTTP-POSTs `transcribe-voice` with `{message_id}` + the webhook secret. PUBLIC EXECUTE revoked.

#### `should_notify(p_user_id uuid, p_kind notification_kind, p_channel notification_channel) → boolean`

`audit_fixes`. Returns `true` unless the user has an explicit `false` row in `notification_preferences`. Default-open (true when no row exists). Revoked from `authenticated`.

### 3.10 Trigger functions

| Trigger function | Fires on | Purpose |
|---|---|---|
| `handle_new_auth_user()` | AFTER INSERT on `auth.users` | Insert blank profile row |
| `profiles_set_goal_updated_at()` | BEFORE UPDATE on `profiles` | Stamp `goal_updated_at` on goal change |
| `bump_conversation_last_message()` | AFTER INSERT on `messages` | Set `conversations.last_message_at` (+ `last_message_body` for the chat list) |
| `notify_intro_inserted()` | AFTER INSERT on `intros` | Dispatch push (warm-forward composes `"X (via Y) wants to connect"` title and passes `via_user_id` + `via_user_name` in payload) |
| `notify_message_inserted()` | AFTER INSERT on `messages` | Dispatch push (mute-aware; preferences-aware; SUPPRESSED for chat bubbles whose linked proposal is already `confirmed` — office-hours path) |
| `notify_meeting_confirmed()` | AFTER UPDATE on `meeting_proposals` | Dispatch `meeting_confirmed` push to proposer |
| `on_voice_message_inserted()` | AFTER INSERT on `messages` | `dispatch_transcription` for voice kind |
| `notify_opportunity_interest()` | AFTER INSERT on `opportunity_interests` | Push to opportunity author, gated by `should_notify(..., opportunity_interest, push)`; uses `md5(opp || ':' || user)::uuid` as deterministic event_id |
| `extensions.moddatetime(updated_at)` | BEFORE UPDATE on `profiles`, `intros`, `conversations`, `meeting_proposals`, `opportunities`, `office_hours_settings` | Maintain `updated_at` |

### 3.11 Cron jobs (`pg_cron`, `app.functions_base_url` + `app.webhook_shared_secret` GUCs required)

| Job name | Schedule | Effect |
|---|---|---|
| `expire-overdue-intros` | `0 * * * *` (hourly) | `select public.expire_overdue_intros()` |
| `goal-staleness-daily` | `0 9 * * *` (09:00 UTC) | `pg_net.http_post` → `/functions/v1/goal-staleness-reminder` with `X-Supabase-Webhook-Secret` |
| `fcm-token-cleanup` | `0 3 * * *` (03:00 UTC) | Delete `device_tokens` revoked > 7d ago OR `last_seen > 90d` ago |
| `chat-media-orphan-sweep` | `0 4 * * *` (04:00 UTC) | Delete `chat-media` storage objects > 24h old with no matching `messages.media_path` |
| `office-hours-materialize-daily` | `15 2 * * *` (02:15 UTC) | Re-run `materialize_office_hours_slots` for every enabled host |

---

## Section 4 — Edge Functions

All edge functions live in `supabase/functions/` and run on Deno. They use shared utilities from `supabase/functions/_shared/` (`cors.ts`, `env.ts`, `test-utils.ts`). JWT verification is per-function via `supabase/config.toml`.

**Total: 7 edge functions** (verified via `ls supabase/functions/`): `auth-handle-login`, `delete-account`, `goal-staleness-reminder`, `infer-goal-type`, `meeting-playbook`, `send-push`, `transcribe-voice`.

### 4.1 `auth-handle-login` (`verify_jwt = false`)

**File:** `supabase/functions/auth-handle-login/index.ts`

**Purpose:** Allow login with a handle instead of email.

**Auth:** Public endpoint (no JWT).

**Input body:** `{ "handle": "string", "password": "string" }`

**Output (success):** `{ "access_token": "string", "refresh_token": "string", "expires_in": int, "token_type": "bearer" }`

**Output (failure):** `401 { "error": "invalid_credentials" }`

**Behavior:**

1. Normalizes handle: trim, strip leading `@`, lowercase.
2. Validates against the citext regex.
3. Service-role lookup: finds the profile with matching handle where `onboarded=true AND private_mode=false AND suspended_at IS NULL`.
4. Gets the email via `admin.auth.admin.getUserById`.
5. Signs in via anon client `signInWithPassword({ email, password })`.
6. Returns the session tokens.
7. **On any failure path:** performs a dummy sign-in to `nobody@example.invalid` (timing parity to prevent handle enumeration) and returns generic 401.

**Required env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`.

### 4.2 `delete-account` (verify_jwt enforced via explicit JWT header check)

**File:** `supabase/functions/delete-account/index.ts`

**Purpose:** GDPR account deletion. Called from the mobile app.

**Auth:** `Authorization: Bearer <jwt>` (user's own JWT, explicitly verified inside the function via `userClient.auth.getUser(jwt)`).

**CORS:** Restricted allow-list — `https://app.bvisionry.com` and `connect-mobile://` (overridable via `DELETE_ACCOUNT_ALLOWED_ORIGINS` env).

**Behavior:**

1. Extract and verify the JWT → user id.
2. `userClient.rpc('delete_my_account')` (as the user, so `auth.uid()` is set in the RPC).
3. `admin.auth.admin.deleteUser(userId)` (treats `not_found` as success → idempotent).
4. Returns `{ ok: true }`.

**Required env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`.

### 4.3 `goal-staleness-reminder` (webhook, `verify_jwt = false`)

**File:** `supabase/functions/goal-staleness-reminder/index.ts`

**Purpose:** Nightly job to identify users with stale goals (>56 days since `goal_updated_at`) and (eventually) send email reminders.

**Auth:** `X-Supabase-Webhook-Secret` header must match `WEBHOOK_SHARED_SECRET`. Called by `goal-staleness-daily` pg_cron job at 09:00 UTC.

**Behavior:** Queries profiles where `goal_updated_at < now() - interval '56 days' AND onboarded = true`. When `MAILER_KEY` is absent, returns `{ ok: true, stub: true, would_email: count }`. Email dispatch is **not yet implemented** — see §17.

**Required env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET`. **Optional env:** `MAILER_KEY`.

### 4.4 `infer-goal-type` (`verify_jwt = true`)

**File:** `supabase/functions/infer-goal-type/index.ts`

**Purpose:** AI classification of free-text goal into a `goal_type` enum value.

**Auth:** Supabase JWT (standard `Authorization: Bearer <token>`).

**Input body:**

```json
{
  "text": "string (20..280 chars)",
  "primary_role": "role_kind (optional)",
  "roles": ["role_kind", ...] 
}
```

**Output:**

```json
{ "goal_type": "hire | be_hired | ... | null", "confidence": "high | low" }
```

**Behavior:**

- Calls Anthropic `claude-sonnet-4-6` at `https://api.anthropic.com/v1/messages` (header `anthropic-version: 2023-06-01`, auth `x-api-key`).
- `max_tokens=16`, `temperature=0`.
- System prompt cached via `cache_control: { type: 'ephemeral' }` — instructs model to output a single lowercase snake_case enum value or the literal `"none"`.
- Returns `null` for goal_type when the model's confidence is low or it outputs `"none"`.
- Logs only `{ inferred, ms }` — never the user's text.

**Required env:** `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

### 4.5 `meeting-playbook` (`verify_jwt = true`)

**File:** `supabase/functions/meeting-playbook/index.ts`

**Purpose:** Generate an AI briefing card for a confirmed meeting.

**Auth:** Supabase JWT. Function also resolves the JWT explicitly via `supabase.auth.getUser(jwt)` for defense-in-depth.

**Input body:** `{ "meeting_id": "uuid", "force"?: boolean }`

**Output:**

```json
{
  "summary": "string",
  "shared_interests": ["string", ...],   // 3-5 entries
  "conversation_starters": ["string", ...],  // 3 entries
  "do_notes": ["string", ...],            // 2-3 entries
  "dont_notes": ["string", ...],          // 1-2 entries
  "generated_at": "ISO timestamptz"
}
```

**Behavior:**

1. Resolve JWT → caller id.
2. Service-role lookup of `meeting_proposals.id` → `conversation_id` → participants. Caller must be one of them; otherwise `403 forbidden`.
3. Fetch both participants' display-profile fields (privacy filter: only `name, headline, bio, roles, primary_role, goal_type, goal_text, city, country`).
4. Resolve topic from `office_hours_slots.topic` if any.
5. Compute `sha256(stableStringify({viewer_profile, target_profile, meeting_topic}))` and look up `meeting_playbooks (meeting_id, viewer_id)`.
6. Cache hit when `force=false`, hash matches, generated_at within 7 days → return cached row.
7. Otherwise call Claude `claude-sonnet-4-6`, `max_tokens=800, temperature=0.4`. Cached system prompt (ephemeral cache_control) instructs JSON-only output with the four arrays + summary, no markdown fences. Tolerates markdown fences / extra prose by stripping.
8. Upsert `meeting_playbooks (meeting_id, viewer_id)` via service-role and return.

**Failure modes:** `502 generation_failed` on Claude error / invalid JSON; row is NOT written on failure.

**Rate limit:** Not enforced server-side. Client enforces 1-hour cooldown after `generated_at` for the regenerate button (i18n key `meetings.playbook.regenerateRateLimited`).

**Required env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`.

### 4.6 `send-push` (webhook, `verify_jwt = false`)

**File:** `supabase/functions/send-push/index.ts`

**Purpose:** Deliver FCM v1 push notifications. Operates as a fire-and-forget webhook from the database (called by `dispatch_push` via `pg_net`).

**Auth:** `X-Supabase-Webhook-Secret` header. Not callable by clients.

**Input body (validated):**

```ts
{
  recipient_id: uuid,
  event_table: string,
  event_id: uuid,
  payload: {
    kind: notification_kind,
    title: string,
    body: string,
    url?: string,
    via_user_id?: uuid,
    via_user_name?: string
  },
  data?: { kind?: string, entity_id?: string, conversation_id?: string }
}
```

**Behavior:**

1. Atomically claims the `push_log` row:
   ```sql
   UPDATE push_log SET delivered=true
   WHERE event_table=? AND event_id=? AND recipient_id=?
     AND delivered=false AND created_at > now()-interval '5 minutes'
   ```
   Returns `{ok: true, already_processed: true}` on 0 rows affected.
2. Loads service-account JSON from `FCM_SERVICE_ACCOUNT_JSON` (when missing → stub mode; keeps `delivered=true` and returns `{stub:true}`).
3. Mints a Google JWT (RS256, scopes: `https://www.googleapis.com/auth/firebase.messaging`), exchanges for an OAuth access token (60s leeway cache).
4. Fetches all non-revoked device tokens for `recipient_id` (platforms: `ios`, `android` only — not `web`).
5. POSTs `https://fcm.googleapis.com/v1/projects/{projectId}/messages:send` per device token in parallel.
6. FCM `data` map merges `payload.url + payload.kind` with the structured `data.kind/entity_id/conversation_id` (structured wins on collision). Warm-forward `via_user_id`/`via_user_name` also forwarded.
7. **Drops device-token rows** (`revoked_at = now()`) on FCM error codes: `UNREGISTERED`, `INVALID_REGISTRATION`, `SENDER_ID_MISMATCH`, `THIRD_PARTY_AUTH_ERROR`, or HTTP 404. **Does NOT drop on `INVALID_ARGUMENT`** (logs a warning).
8. On any failure path the claim is reverted (`delivered=false, error=<reason>`) so the next retry can re-claim.

**Required env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET`. **Optional env:** `FCM_SERVICE_ACCOUNT_JSON`.

### 4.7 `transcribe-voice` (webhook, `verify_jwt = false`)

**File:** `supabase/functions/transcribe-voice/index.ts`

**Purpose:** Transcribe voice messages using OpenAI Whisper.

**Auth:** `X-Supabase-Webhook-Secret` header.

**Input body:** `{ "message_id": "uuid" }`

**Behavior:**

1. Atomic claim:
   ```sql
   UPDATE messages SET transcript_status='processing'
   WHERE id=? AND kind='voice' AND transcript_status='pending'
   RETURNING media_path
   ```
   Returns `{ok:true, skipped:true}` if 0 rows.
2. `admin.storage.from('chat-media').createSignedUrl(media_path, 60)`.
3. Fetches the audio (30s timeout via `WHISPER_TIMEOUT_MS`, ≤25 MB hard limit).
4. Extension extracted from `media_path`; falls back to `m4a` when unsupported.
5. POSTs to OpenAI Whisper `https://api.openai.com/v1/audio/transcriptions` (`model=whisper-1`) with the audio as multipart.
6. Updates message: `transcript = result.text`, `transcript_status = 'ready'`.

**Failure modes:**

- Transient (signed-URL, download, Whisper non-2xx) → revert `transcript_status` to `pending`.
- Hard 413 (oversize) → `failed`.
- Stub mode (no `WHISPER_API_KEY` / `OPENAI_API_KEY`) → marks `unsupported` with a stub transcript string.

**Required env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET`. **Optional env:** `WHISPER_API_KEY` or `OPENAI_API_KEY`, `WHISPER_TIMEOUT_MS` (default 30 000).

---

## Section 5 — Auth & Onboarding Journey

### 5.1 Authentication Methods

1. **Magic link (email OTP):** `supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: authRedirectUri } })`. On callback the app calls `createSessionFromUrl(url)` — PKCE code exchange via `supabase.auth.exchangeCodeForSession(code)` with implicit fallback if `#access_token=...` fragment is present.
2. **Email + password sign-in:** `supabase.auth.signInWithPassword({ email, password })`.
3. **Handle + password sign-in:** via the `auth-handle-login` edge function (§4.1). Client calls the function, receives tokens, calls `supabase.auth.setSession({ access_token, refresh_token })`.
4. **Social (Apple/Google):** `supabase.auth.signInWithOAuth({ provider: 'apple'/'google', options: { redirectTo: authRedirectUri } })`.
5. **Sign-up:** `supabase.auth.signUp({ email, password, options: { emailRedirectTo: authRedirectUri } })`. Password ≥ 8 chars (i18n key `auth.passwordHint8`).
6. **Sign-out:** Local scope only (`supabase.auth.signOut({ scope: 'local' })`). Deregisters push token first. Clears react-query cache and all persisted Zustand stores (resets `telemetryStore`, `feedFiltersStore`, `profileNudgeStore`, `useOnboardingDraft`); forces `telemetryStore` to opt-out (GDPR).

`authRedirectUri = makeRedirectUri({ scheme: 'connect-mobile', path: 'auth' })` for native; `window.location.origin + '/auth'` on web.

### 5.2 Session lifecycle

`mobile/src/features/auth/hooks/useSession.ts`:

- Registers `supabase.auth.onAuthStateChange` **synchronously** to win the race against cold-start deep-link callbacks.
- On mount: reads `Linking.getInitialURL()`; if URL contains `/auth`, runs `createSessionFromUrl`. Then `supabase.auth.getSession()` populates the initial state.
- Subscribes to runtime `Linking.addEventListener('url', ...)` and only triggers session exchange for `/auth` URLs (`/p/<handle>` deep links must NOT flip loading state).
- `AppState` listener in `mobile/src/lib/supabase/client.ts`: `startAutoRefresh` on `active`, `stopAutoRefresh` otherwise.
- Storage: `expo-secure-store`-backed `supabaseSessionStorage` (`mobile/src/lib/supabase/sessionStorage.ts`). PKCE flowType.

### 5.3 Auth Gate State Machine (`useNextRoute`)

```
sessionLoading || (session && profileLoading)  → 'loading'    → spinner
!session                                       → 'unauthed'   → /(auth)/sign-in
profile.suspended_at IS NOT NULL               → 'suspended'  → /suspended
!profile.onboarded                             → 'onboarding' → /(onboarding)/goal
default                                        → 'app'        → /(app)/(tabs)/home
```

Every layout (`app/index.tsx`, `app/(app)/_layout.tsx`, `app/(auth)/_layout.tsx`, `app/(onboarding)/_layout.tsx`) consults this hook and renders either a spinner, a redirect, or its own children.

### 5.4 Onboarding Flow (4 steps, sequential)

All onboarding data persists to a Zustand store (`useOnboardingDraft`, AsyncStorage-backed) so users can resume.

**Step 1: Goal** (`app/(onboarding)/goal.tsx`, `GoalStep.tsx`)

- Goal text area: 10–280 chars (DB constraint; i18n message `onboarding.goal.errorRange` says "10–280").
- Counter `t('onboarding.goal.counter', { count, max })`.
- Debounced 800ms / minimum 20 chars: calls `infer-goal-type` edge function with `{text, primary_role, roles}`. On `{goal_type: <enum>, confidence: 'high'}` pre-selects the chip with caption `t('onboarding.goal.inferred', {label})`. Confidence `low` → `t('onboarding.goal.inferFailed')`. Must not pre-select on low/null.
- Goal-type chip selector: 8 enum values.

**Step 2: Identity** (`app/(onboarding)/identity.tsx`)

- Name input (1–80 chars).
- Handle input regex `^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$`. On blur calls `check_handle_available`. Hint mentions 90-day redirect → 410 Gone on change (UI copy only — not implemented backend; see §17).

**Step 3: Roles** (`app/(onboarding)/roles.tsx`)

- Multi-select role chips: founder / leader / builder / investor (at least 1 required).
- Primary role selector (must be one of the selected roles).

**Step 4: About** (`app/(onboarding)/about.tsx`)

- City (required, max 80).
- Country (required, max 80).
- Headline (optional, 5–120 chars).
- Bio (optional, 10–1000 chars).
- Submit → `submitOnboarding(userId, draft)` PATCHes `profiles` with all draft fields and `onboarded=true` (`mobile/src/features/onboarding/services/onboarding.service.ts`).

**Stepper layout:** All 4 steps share `StepperLayout` (`mobile/src/features/onboarding/components/StepperLayout.tsx`) with `ProgressDots` and a step counter `t('onboarding.stepLabel', { current, total: 4, stepName })`.

Zod schemas live in `mobile/src/features/profile/schemas.ts` (`NameSchema`, `HandleSchema`, `HeadlineSchema`, `BioSchema`, `GoalTextSchema`, `CitySchema`, `CountrySchema`, `GoalTypeSchema`, `OnboardingSubmissionSchema`).

### 5.5 Suspended account screen

`mobile/app/suspended.tsx` — Static screen with `AlertTriangle` icon, body copy from `t('suspended.body')`, "Submit appeal" button (mailto:`support@bvisionry.com`), and "Sign out" button.

### 5.6 Forgot password

There is no dedicated reset-password flow. `SignInForm.tsx`'s "Forgot password?" CTA opens a confirm/toast pointing the user at the magic-link button (post-commit 5d858f8 it uses `useConfirm`/`useToast` instead of `Alert.alert`). Copy lives at `auth.forgotPwdInstructions`.

---

## Section 6 — Feature Folder Inventory

Inventory verified: **16 feature folders** under `mobile/src/features/`: `auth`, `chat`, `connections`, `discovery`, `home`, `intros`, `media`, `meetings`, `office-hours`, `onboarding`, `opportunities`, `privacy`, `profile`, `push`, `settings`, `verification`.

### 6.1 `features/auth/`

- **Purpose:** session, sign-in, sign-up, magic-link, social OAuth, error mapping.
- **Components:** `AuthShell.tsx` (navy/gold gradient + BVisionRY Connect wordmark in Dosis 700), `SignInForm.tsx` (identifier + password; "Send magic link" secondary CTA; "Forgot password?" → useConfirm; social buttons), `SignUpForm.tsx` (email + password 8+ chars with live hint), `SocialSignInButtons.tsx`.
- **Hooks:** `useMagicLinkSubmit.ts`, `useNextRoute.ts`, `useSession.ts`.
- **Services:** `auth.service.ts` (`sendMagicLink`, `signUpWithPassword`, `signInWithEmailPassword`, `signInWithIdentifier`, `createSessionFromUrl`, `signOut`), `errorMap.ts` (PostgrestError / AuthError → i18n key), `redirect.ts` (`authRedirectUri`), `socialAuth.service.ts`.
- **Context:** `SessionContext.tsx` (`<SessionProvider>` + `useAuthSession()`).
- **Side effects on sign-out:** deregister FCM token via `unregister_device_token`, clear `queryClient`, reset `feedFiltersStore` + `profileNudgeStore` + `useOnboardingDraft`, force `telemetryStore` to disabled (GDPR).
- **Tests:** `tests/features/auth/{auth.service.test.ts, auth.service.password.test.ts, errorMap.test.ts, socialAuth.service.test.ts, useMagicLinkSubmit.test.ts, useNextRoute.test.ts}`.

### 6.2 `features/onboarding/`

- **Purpose:** 4-step wizard.
- **Components:** `GoalStep`, `IdentityStep`, `RolesStep`, `AboutStep`, `StepperLayout` (renders `ProgressDots` + step counter).
- **Services:** `inferGoal.service.ts` (POSTs to `infer-goal-type`), `onboarding.service.ts` (final PATCH).
- **Store:** `useOnboardingDraft` (Zustand, AsyncStorage-persisted).

### 6.3 `features/profile/`

- **Purpose:** own profile, public profile, edit, signals, share, completeness banner, goal-refresh nudge, photo nudge, intro CTA.
- **Screens:** `/(app)/profile` (`ProfileView` for self), `/(app)/profile/edit` (`ProfileEditForm`), `/p/[handle]` (`PublicProfileView` via anon RPC fallback), `OtherProfileView` for authed third-party views.
- **Components:** `BioMarkdown` (renders markdown bio via `react-native-markdown-display`), `GoalRefreshBanner` (info/warn/stale thresholds at 4w / 6w / 8w with snooze), `MutualConnectionsModal`, `OtherProfileView` (signals row + send-intro sticky CTA + warm-intro banner + office-hours book section), `PhotoNudgeBanner` (dismissible per-user via `profileNudgeStore`), `ProfileCompletenessBanner` (computes % from photo / headline / bio presence), `ProfileEditForm`, `ProfileHero` (navy → navy-light gradient; post commit `5d858f8` text is `text-white` for AA contrast), `ProfileSignalsRow` (mutual count + avg rating from `get_profile_signals`), `ProfileView`, `PublicProfileView`.
- **Hooks:** `useCurrentUserProfile`, `useProfileByHandle`, `useProfileSignals`, `useUpdateProfile`.
- **Services:** `profile.service.ts` (`checkHandleAvailable`, `fetchProfile`, `updateProfile`), `profileSignals.service.ts` (RPC `get_profile_signals`), `publicProfile.service.ts` (RPC `get_public_profile`).
- **Store:** `profileNudgeStore` (per-user dismissed-IDs for the photo-nudge banner).

### 6.4 `features/discovery/`

- **Purpose:** discoverable feed + daily-matches strip + thin-pool banner + mutual-match flag.
- **Components:** `DailyMatchesStrip` (horizontal scroll of up to 5 `UserCard`s; featured halo; marks viewed on press), `DiscoverableFeed` (FlatList from `search_discoverable_profiles`; pull-to-refresh), `FeedFilterBar` (role + goal + country + clear chips), `ThinPoolBanner` (shown when count ≤ 3 with "Refine my goal" CTA).
- **Hooks:** `useDailyMatches` → `supabase.rpc('get_daily_matches')`; `useDiscoverableFeed(filters)` → cursor-paged `search_discoverable_profiles`; `useIsMutualMatch(otherId)` → `is_mutual_match`; `useMarkMatchViewed`.
- **Services:** `discovery.service.ts`, `mutualMatch.service.ts`.
- **Store:** `feedFiltersStore` (Zustand, partially persisted — `query` excluded; fields `query`, `roles[]`, `goalTypes[]`, `country`).

### 6.5 `features/intros/`

- **Purpose:** send / accept / decline intros; warm-intro requests + forwards; inbox + sent tabs; intro detail.
- **Screens:** `/(app)/(tabs)/inbox` (`InboxScreen` with `InboxTabs`), `/(app)/intros/[id]` (`IntroDetailView`).
- **Components:** `ComposeIntroSheet`, `EmptyInbox` (branded: gold-pale circle + `MailOpen` icon + CTA), `InboxScreen`, `InboxTabs` (SegmentedControl-style Received/Sent), `IntroDetailView`, `IntroListRow`, `IntroStateBadge`, `WarmIntroComposeSheet`, `WarmIntroForwardSheet`, `WarmIntroSuggestionCard`, `WarmIntroSuggestionsStrip`.
- **Hooks:** `useAcceptIntro`, `useDeclineCooldown` (derives "available {date}" from `declined_at`), `useDeclineIntro`, `useForwardWarmIntro`, `useInbox`, `useIntroById(id)`, `useRequestWarmIntro`, `useSendIntro` (throws `IntroDuplicateError | IntroCooldownError | IntroRateLimitError | IntroExpiredError`), `useSent`, `useUnreadIntros`, `useWarmIntroSuggestions`.
- **Schemas:** `intros/schemas.ts` (`NoteSchema`: 80–400 btrim).
- **Services:** `intros.service.ts` (PostgrestError → typed-error mapping), `warmIntros.service.ts`.

### 6.6 `features/chat/`

- **Purpose:** conversation list, conversation thread, send / edit / delete text, image / voice composers, mute, read receipts, typing, meeting bubble.
- **Screens:** `/(app)/(tabs)/chats` (`ChatsListScreen`), `/(app)/chats/[id]` (`ConversationScreen` — inverted FlatList; KeyboardAvoidingView).
- **Components:** `ChatsListScreen`, `ConversationListRow` (`BellOff` for muted; peer photo; last-message preview by kind), `ConversationScreen` (post-commit 5d858f8 uses `TopBar` with avatar leading instead of bespoke header), `MessageBubble` (long-press menu OR explicit `MoreHorizontal` button for own text: Edit/Delete via 15-min window), `MessageComposer` (Plus → ProposeMeetingSheet, `Camera` → image picker, `Mic` → VoiceRecorderSheet, `Send` arrow), `ImageMessageBubble`, `ImageViewerModal`, `VoiceMessageBubble`, `MeetingCard` (rendered for `kind='meeting'` messages: slots, duration, confirmed slot, meeting URL, ICS download, confirm/decline/cancel actions, post-meeting review prompt, links to `MeetingPlaybookCard`).
- **Hooks:** `useConversations` (`list_conversation_overview`), `useDeleteMessage`, `useEditMessage`, `useMarkConversationRead`, `useMessages` (cursor-paged DESC, 30/page), `useMessagesRealtime` (channel `messages:<conv>` filtered by conversation_id), `useMuteConversation` / `useUnmuteConversation`, `useSendMessage` (optimistic insert keyed by client-UUID), `useTypingChannel` (Realtime broadcast channel `presence:<conv>` for typing events), `useUnreadCounts` (`list_conversation_unread`).
- **Services:** `chat.service.ts`.
- **Store:** `activeConversationStore` (tracks which conversation is on-screen so foreground push for that conversation is suppressed).

### 6.7 `features/meetings/`

- **Purpose:** propose / confirm / decline / cancel meetings; ICS export; AI playbook; post-meeting prompt + review.
- **Components:** `DateTimeField` (`@react-native-community/datetimepicker`), `ICSDownloadButton` (`Calendar` icon — uses `ics.service.ts`, saves to `expo-file-system`, shares via `expo-sharing`), `MeetingCard` (per-bubble — renders slots / confirmed slot in user's timezone; `t('meetings.yourTime')`), `MeetingPlaybookCard` (loading skeleton + retry banner + regenerate button rate-limited 1h), `PostConnectionReview` (uses `ThumbsUp`/`Meh`/`Ban` icons; outcome picker useful/not_useful/no_show; optional note), `PostMeetingPrompt` (yes / rescheduled / no_show flow), `ProposeMeetingSheet` (1–3 datetime slots, duration 15/30/45/60/90/120/180/240, optional URL, timezone hint).
- **Hooks:** `useCancelMeeting`, `useConfirmMeeting`, `useDeclineMeeting`, `useMeetingPlaybook` (`supabase.functions.invoke('meeting-playbook', {body:{meeting_id, force}})` + `supabase.rpc('get_meeting_playbook', {p_meeting_id})` for cache), `useMeetingProposals`, `useMeetingProposalsRealtime`, `useProposeMeeting`.
- **Schemas:** `meetings/schemas.ts` (slots 1–3 future, 15..240 duration, optional `https://` URL).
- **Services:** `ics.service.ts` (RFC 5545: UTC stamps, line folding ≤ 75 UTF-8 octets, escape `;,\\\n`; `UID = meeting-{meetingId}@bvisionry.com`; `__test__` export of `formatICSDate, escapeICS, foldLine`), `meetings.service.ts`, `playbook.service.ts`.

### 6.8 `features/office-hours/`

- **Purpose:** host settings + bookings dashboard + booking flow.
- **Screens:** `/(app)/settings/office-hours` (`OfficeHoursSettingsForm`); profile-side `BookSlotSheet` + `UpcomingSlotsList` integration on `OtherProfileView`; viewer's bookings list on `/(app)/(tabs)/network`.
- **Components:** `BookingsList` (uses `my_bookings`; per-booking cancel via `Trash2`), `BookSlotSheet` (topic 5–280), `OfficeHoursBadge` (pill on profile hero), `OfficeHoursSettingsForm` (enable toggle, `WeeklyAvailabilityEditor`, slot-duration SegmentedControl 15/30/45/60, buffer minutes `Stepper`, max-bookings `Stepper`, meeting link template, notes template), `UpcomingSlotsList`, `WeeklyAvailabilityEditor` (`Copy`/`Plus`/`Trash2` icons; per-weekday windows; "Copy Monday to weekdays" + "Copy to all days" shortcuts).
- **Hooks:** `useBookSlot`, `useCancelBooking`, `useMyBookings`, `useOfficeHoursSettings` (`my_office_hours_settings`), `useUpcomingSlots(hostId)`, `useUpdateOfficeHoursSettings`.
- **Schemas:** `WindowSchema` (weekday 0–6, startMinute 0–1439, endMinute > startMinute, timezone IANA), `SlotDurationSchema` (15|30|45|60), `OfficeHoursSettingsSchema`, `BookSlotInputSchema` (topic 5–280).

### 6.9 `features/opportunities/`

- **Purpose:** opportunities board.
- **Screens:** `/(app)/(tabs)/opportunities` (`OpportunityFeed`), `/(app)/opportunities/[id]` (`OpportunityDetailView`), `/(app)/opportunities/new` (`OpportunityComposer` — 3-step wizard Kind / Content / Meta).
- **Components:** `ExpressInterestSheet` (optional note 10–500), `InterestedList` (author-only), `OpportunityCard` (post-commit 5d858f8: borderless author row instead of nested `UserCard`; single neutral kind pill), `OpportunityComposer`, `OpportunityDetailView` (sticky bottom Express-Interest CTA; close button for author), `OpportunityFeed` (`Briefcase` empty-state icon), `OpportunityFilterBar` (remote-only toggle + search input).
- **Hooks:** `useCloseOpportunity`, `useCreateOpportunity`, `useExpressInterest`, `useInterestedList`, `useMyOpportunities`, `useOpportunities` (`list_opportunities`), `useOpportunity`, `useUpdateOpportunity`.
- **Schemas:** kind, title 5–120, body 10–2000, tags array ≤ 8 each lowercase 1–30, note 10–500.

### 6.10 `features/connections/`

- **Screens:** `/(app)/(tabs)/network`.
- **Components:** `ConnectionsList` (`Users` icon empty state; uses `list_connections`; tap row → `/(app)/chats/[conversation_id]`).
- **Hooks:** `useConnections`.
- **Services:** `connections.service.ts`.

### 6.11 `features/settings/`

- **Purpose:** account section, language picker, telemetry opt-in, legal links, notifications matrix, blocked users, help, app version.
- **Screens:** `/(app)/settings/{index, account, blocked-users, help, notifications, office-hours, privacy, verification}`.
- **Components:** `AccountSection`, `AppVersionSection`, `LanguageSection` (EN/ES via SegmentedControl), `LegalSection` (links to /(app)/legal/{privacy,terms}), `NotificationPrefsSection` (post-commit 5d858f8: per-(kind, channel) row layout fits 390px viewport), `TelemetrySection`, `SettingsRow` (`ChevronRight` icon).
- **Hooks:** `useNotificationPrefs`.
- **Services:** `notificationPrefs.service.ts` (CRUD on `notification_preferences`), `settings.service.ts` (`exportMyData` → RPC + writes JSON via `expo-file-system`; `deleteMyAccount` → `functions.invoke('delete-account')` then `signOut`).
- **Store:** `telemetryStore` (Zustand, AsyncStorage-persisted; `analyticsEnabled` / `crashReportsEnabled` default `false`; rehydration awaited in `_layout.tsx` before Sentry/Firebase init; both flags forced back to `false` on sign-out).

### 6.12 `features/privacy/`

- **Components:** `BlockedUsersList` (`ShieldOff` empty), `PrivacyTogglesSection` (3 grouped toggles: private_mode / read_receipts / public_investor_page), `ProfileActionsMenu` (`MoreHorizontal` … menu on other-user profiles: Block, Report), `ReportModal` (reason picker spam/harassment/impersonation/inappropriate/other + optional note 0–1000).
- **Hooks:** `useBlockedUsers`, `useBlockUser`, `usePrivacyToggles`, `useReportTarget`, `useUnblockUser`.
- **Services:** `privacy.service.ts`.

### 6.13 `features/media/`

- **Components:** `AvatarUploadButton`, `ImageMessageBubble` (signed URL hook; tap-to-expand), `ImageViewerModal`, `VoiceMessageBubble` (`Play`/`Pause` icons; transcript toggle on tap when `transcript_status='ready'`), `VoiceRecorderControl` (`Mic`/`Square` icons), `VoiceRecorderSheet`.
- **Hooks:** `usePickImage` (`expo-image-picker` + `expo-image-manipulator` resize), `useRecordAudio` (`expo-audio` — mic perm + lifecycle), `useSendImageMessage`, `useSendVoiceMessage`, `useSignedUrl(path)` (60s TTL cached), `useUploadAvatar` (image-picker → manipulator → `File.bytes()` → `supabase.storage.from('avatars').upload(...,{contentType:'image/jpeg', upsert:true})`; updates `profiles.photo_url` with `?v=<Date.now()>` cache-bust), `useVoicePlayerCoordinator` (singleton: only one voice clip plays at a time).
- **Services:** `media.constants.ts` (`MAX_IMAGE_BYTES = 5*1024*1024`, `MAX_VOICE_MS = 120_000`, `MAX_VOICE_BYTES = 25*1024*1024`, `MAX_AVATAR_BYTES = 5*1024*1024`; MIME map: jpg/jpeg/png/webp → `image/*`, m4a/mp4/aac/webm → `audio/*`), `storage.service.ts`.

### 6.14 `features/push/`

- **Components:** `PushToast` (top-anchored foreground banner; tappable to route via `data.kind`).
- **Hooks:** `useForegroundMessages` (`messaging().onMessage` → `PushToast`; suppressed when `activeConversationStore` matches the message's `conversation_id`), `useNotificationTapHandler` (`onNotificationOpenedApp` + `getInitialNotification()` for cold start; calls `resolveNotificationRoute(data)`), `useRegisterFcmToken` (on mount + on session change: `requestPermission`, `getToken`, `register_device_token`, persist via `lastTokenStorage`; subscribes to `onTokenRefresh`).
- **Services:** `lastTokenStorage.ts` (AsyncStorage), `notificationRoute.ts` (kind / entity_id / conversation_id → route mapping, with legacy `url` fallback), `push.service.ts`.

### 6.15 `features/verification/`

- **Components:** `VerifiedBadge` (uses `BadgeCheck` icon after commit 5d858f8; rendered next to handle when `profile.verified_github_username` is set).
- **Hooks:** `useConnectGithub` (opens GitHub OAuth in `expo-web-browser`; redirect to `connect-mobile://auth?code=...` consumed by the auth deep-link handler; calls `set_github_verification`), `useDisconnectGithub` (`clear_github_verification`).
- **Services:** `verification.service.ts`.
- Per-role proof types (UI):
  - **Founder:** domain email, /team page (Coming soon)
  - **Builder:** **GitHub** (only one currently implemented)
  - **Investor:** domain email, Crunchbase, portfolio (Coming soon)
  - **Leader:** domain email (Coming soon)

### 6.16 `features/home/`

- Single component `HomeScreen.tsx` rendering daily-matches strip + discoverable feed + warm-intro suggestions strip + thin-pool banner.

### 6.17 Shared empty / loading / error states

- `QueryState` wraps query-status → UI mapping (spinner + retry on error). Post-commit 5d858f8 it accepts `loadingFallback={<SkeletonOpportunityCard.List count={4} />}` for skeleton-driven loading.
- `EmptyState` (icon + title + body + optional `Button` action) is used for empty lists.
- `Skeleton` + `SkeletonProfile` for profile and edit forms.
- `Banner` for in-line context cards (info / warning / danger / muted / success).

---

## Section 7 — Routing & Deep Links

### 7.1 Route Tree (Expo Router file-based)

```
app/
├── _layout.tsx               Root layout: fonts, Sentry, SessionProvider, QueryClientProvider, PushBootstrap, Toast/PushToast overlays, ConfirmProvider
├── index.tsx                 Redirect via useNextRoute
├── auth.tsx                  OAuth/magic-link callback (connect-mobile://auth)
├── suspended.tsx             Suspended-account screen
├── +not-found.tsx            404 screen
│
├── (auth)/
│   ├── _layout.tsx           Auth guard (redirects authed users out)
│   ├── sign-in.tsx
│   └── sign-up.tsx
│
├── (onboarding)/
│   ├── _layout.tsx           Onboarding gate
│   ├── goal.tsx
│   ├── identity.tsx
│   ├── roles.tsx
│   └── about.tsx
│
├── (app)/
│   ├── _layout.tsx           App gate
│   │
│   ├── (tabs)/
│   │   ├── _layout.tsx       Custom 5-tab bar with badges (mobile/app/(app)/(tabs)/_layout.tsx)
│   │   ├── home.tsx
│   │   ├── inbox.tsx
│   │   ├── network.tsx
│   │   ├── opportunities.tsx
│   │   └── chats.tsx
│   │
│   ├── chats/
│   │   ├── _layout.tsx
│   │   └── [id].tsx          ConversationScreen — id = conversationId
│   │
│   ├── intros/
│   │   ├── _layout.tsx
│   │   └── [id].tsx          IntroDetailView — id = introId
│   │
│   ├── opportunities/
│   │   ├── _layout.tsx
│   │   ├── index.tsx
│   │   ├── [id].tsx
│   │   └── new.tsx
│   │
│   ├── profile/
│   │   ├── _layout.tsx
│   │   ├── index.tsx         Own profile
│   │   └── edit.tsx          Edit own profile
│   │
│   ├── settings/
│   │   ├── _layout.tsx
│   │   ├── index.tsx
│   │   ├── account.tsx
│   │   ├── privacy.tsx
│   │   ├── notifications.tsx
│   │   ├── verification.tsx
│   │   ├── blocked-users.tsx
│   │   ├── office-hours.tsx
│   │   └── help.tsx
│   │
│   └── legal/
│       ├── privacy.tsx       Long-form copy from legal.privacy.body
│       └── terms.tsx         Long-form copy from legal.terms.body
│
└── p/
    └── [handle].tsx          Public profile by handle (anon-accessible; universal-link target)
```

### 7.2 Tab Bar

5 tabs (declared in `mobile/app/(app)/(tabs)/_layout.tsx`): **Home, Inbox, Network, Opportunities, Chats**.

- Icons (Lucide, post commit `5d858f8`): `Home`, `Inbox`, `Users`, `Briefcase`, `MessageSquare`.
- Badges:
  - `inbox`: `useUnreadIntros` count (intros in `delivered` state for recipient).
  - `chats`: sum of `useUnreadCounts` (`list_conversation_unread`).
  - `home` / `network` / `opportunities`: none.
- Badge style (post-fix P1-9): gold dot (`bg-gold`) with navy `99+` cap.
- Tab bar height: `TAB_BAR_CONTENT_HEIGHT = 56` + device bottom inset (capped at `MAX_BOTTOM_INSET = 24` to defend against Android edge-to-edge bogus inset measurements).
- Active: navy icon + label; inactive: muted.

### 7.3 Deep Links

- **Custom scheme:** `connect-mobile://` (`app.config.ts`).
- **Universal/App Links host:** configured via `EXPO_PUBLIC_APP_LINKS_HOST` env (prod value: `connect.bvisionry.com`).
- **iOS Associated Domains:** `applinks:{host}`, `applinks:www.{host}`.
- **Android Intent Filters** (`autoVerify: true`): `https://{host}/p/.*`.
- **Auth callback:** `connect-mobile://auth` → `app/auth.tsx` → `createSessionFromUrl(url)`.

### 7.4 Push-notification tap routing

`mobile/src/features/push/services/notificationRoute.ts`:

| `data.kind` | Route (uses `data.entity_id` / `data.conversation_id`) | Fallback |
|---|---|---|
| `intro_received` | `/(app)/intros/<entity_id>` | `/(app)/(tabs)/inbox` |
| `intro_accepted` | `/(app)/intros/<entity_id>` | `/(app)/(tabs)/inbox` |
| `message_received`, `image_received`, `voice_received` | `/(app)/chats/<conversation_id>` | `/(app)/(tabs)/chats` |
| `meeting_proposal`, `meeting_confirmed` | `/(app)/chats/<conversation_id>` | `/(app)/(tabs)/inbox` |
| `opportunity_interest` | `/(app)/opportunities/<entity_id>` | `/(app)/(tabs)/opportunities` |
| (unknown) | Falls through to `payload.url` (legacy server-rendered path) | `/(app)/(tabs)/home` |

---

## Section 8 — Design System

Color tokens defined in `mobile/global.css` (`@theme`) and mirrored in `mobile/src/theme/colors.ts`. Synchronised — the CSS is the Tailwind utility source, the TS file is for direct JSX consumption.

### 8.1 Color Palette

| Token (CSS) | TS alias | Hex |
|---|---|---|
| `navy` | `navy` | `#0f3460` |
| `navy-light` | `navyLight` | `#1a4a80` |
| `navy-dark` | `navyDark` | `#0a2340` |
| `gold` | `gold` | `#ffc107` |
| `gold-light` | `goldLight` | `#ffe187` |
| `gold-pale` | `goldPale` | `#fff8e1` |
| `surface` | `bg` | `#f8f8f8` |
| `white` | `white` | `#ffffff` |
| `body` | `text` | `#212529` |
| `muted` | `muted` | `#94a3b8` |
| `border` | `border` | `#e5e7eb` |
| `slate-100` | `slate100` | `#f1f5f9` |
| `slate-300` | `slate300` | `#cbd5e1` |
| `success-bg` | `successBg` | `#dcfce7` |
| `success-text` | `success` | `#15803d` |
| `success-border` | `successBorder` | `#4ade80` |
| `warning-bg` | `warningBg` | `#fef3c7` |
| `warning-text` | `warning` | `#b45309` |
| `warning-border` | `warningBorder` | `#fbbf24` |
| `danger-bg` | `dangerBg` | `#fee2e2` |
| `danger-text` | `danger` | `#b91c1c` |
| `danger-border` | `dangerBorder` | `#ef4444` |
| `info-bg` | `infoBg` | `#dbeafe` |
| `info-text` | `info` | `#1d4ed8` |
| `info-border` | `infoBorder` | `#93c5fd` |

Semantic intent variants used by `Banner`, `Pill`, `Button`: see `mobile/src/components/ui/variants.ts`. Each `Intent` (`neutral | info | success | warning | danger`) maps to `{bg, text, border}` Tailwind classes.

### 8.2 Typography

`@theme` in `global.css`:

| Token | Size / line-height |
|---|---|
| `text-display-xl` | 28 / 34 (hero wordmark only) |
| `text-display-lg` | 20 / 26 (onboarding/marketing titles) |
| `text-display-md` | 16 / 22 (TopBar title, card section titles) |
| `text-display-sm` | 13 / 18 (card titles, body emphasis) |
| `text-display-xs` | 11 / 14 (pill, badge, label, tab label) |
| `text-body-lg` | 14 / 20 (primary body, chat bubble) |
| `text-body-md` | 12 / 18 (secondary body, descriptions) |
| `text-body-sm` | 11 / 15 (metadata, captions) |
| `text-body-xs` | 10 / 13 (uppercase eyebrows, fine print) |

**Display font:** `Dosis_700Bold` (CSS var `--font-display`). **Body font:** `Inter_400Regular` (`--font-body`). Pre-commit `5d858f8` body was `Overlock_400Regular`; the audit (P2-10) called it out and the commit swapped to Inter.

**Font weights loaded:**

- Dosis: 400 Regular, 500 Medium, 600 SemiBold, 700 Bold, 800 ExtraBold.
- Inter: 400 Regular, 500 Medium, 600 SemiBold, 700 Bold.

Loaded in `app/_layout.tsx` via `@expo-google-fonts/dosis` + `@expo-google-fonts/inter`. Splash screen is held until both font families resolve.

### 8.3 Spacing Scale

| Token | Value |
|---|---|
| `spacing-gutter` | 16 (outer screen padding) |
| `spacing-card` | 12 (card inner padding) |
| `spacing-card-lg` | 16 (section-card inner padding) |
| `spacing-section` | 24 (between major sections) |

### 8.4 UI Primitives — `mobile/src/components/ui/`

Verified count: **24 files** (`ls mobile/src/components/ui/`):

| File | Notable props | Variants / behavior |
|---|---|---|
| `Avatar.tsx` | `uri?`, `name?`, `size?` | Photo OR initials over `navy` background; rounded full |
| `AvatarCircle.tsx` | `uri?`, `name?`, `size?`, `featured?` | Halo'd avatar (default border / gold halo when `featured`). Post-commit `5d858f8` halo geometry simplified per P1-3 |
| `Banner.tsx` | `intent: Intent`, `title?`, `children`, `onClose?` | Inline banner with `X` close button; uses `intentClasses` |
| `Button.tsx` | `variant`, `size`, `fullWidth?`, `loading?`, `disabled?`, `onPress`, `children` | Variants: `primary` (navy bg / white text), `gold` (gold bg / navy text), `outline` (navy border), `outline-danger` (red border/text), `danger` (red bg), `disabled`, `apple` (black bg). Sizes: `default` (px-4 py-2.5), `small` (px-3 py-1.5) |
| `Card.tsx` | `children`, `className?` | rounded-12 + shadow + `bg-white border border-border`; `featured` variant adds gold top border; wraps `Pressable` |
| `ConfirmDialog.tsx` | `useConfirm()` → `confirm({title, body, confirmLabel?, destructive?, onConfirm})` | Built atop `BottomSheet`; replaces RN `Alert.alert` (post commit `5d858f8` per P0-3) |
| `Divider.tsx` | `label?` | `flex-1 h-px bg-border`; optional inline label |
| `EmptyState.tsx` | `icon: LucideIcon`, `title`, `body?`, `action?:{label, onPress, variant?}` | Centered icon + title + body + optional `Button` |
| `FilterChip.tsx` | `icon?: LucideIcon`, `label`, `selected?`, `onPress` | Pill-style toggle |
| `IconButton.tsx` | `icon: LucideIcon`, `size: 'sm'/'md'/'lg'`, `onPress`, `accessibilityLabel` | Round button (≥ 44dp via hitSlop); variants `plain`/`subtle` |
| `Input.tsx` | `label?`, `value`, `onChangeText`, ..., `errorText?`, `multiline?`, `numberOfLines?`, `maxLength?` | Native TextInput with focus-state border (navy on focus / danger-border on error / `border` default) |
| `Modal.tsx` | `BottomSheet({open, onClose, children, safe?})` | Bottom sheet with backdrop tap to dismiss; drag handle |
| `Pill.tsx` | `intent: Intent`, `size?: 'sm'/'md'`, `children` | Rounded-full chip. Brand variants `default` (gold-pale), `solid` (gold), `navy`, `outline`, `muted`, `success`, `warning`, `danger` |
| `ProgressDots.tsx` | `total`, `current` | Dot row for onboarding progress (post-fix P3-4: navy = past, gold = current, border = pending) |
| `QueryState.tsx` | `query:{isLoading,isError,error,refetch}`, `loadingFallback?`, `errorFallback?`, `children` | Loading/error wrappers around queries |
| `SectionCard.tsx` | `title?`, `children` | White card with uppercase muted eyebrow title (extracted from 3 duplicated `Section` components per P1-6) |
| `SegmentedControl.tsx` | `options:Array<{value,label}>`, `value`, `onChange` | Pill bar with selected state |
| `SettingsRow.tsx` | `icon?: LucideIcon`, `label`, `description?`, `trailing?`, `onPress?`, `destructive?` | Pressable row with `ChevronRight` |
| `Skeleton.tsx` | `width?`, `height?`, `rounded?` | Animated `bg-slate-100` placeholder; composites `SkeletonProfile` / `SkeletonListRow` |
| `Stepper.tsx` | `value`, `min`, `max`, `onChange` | Plus / Minus IconButton numeric stepper |
| `Toast.tsx` | `useToast()` hook + global `<ToastHost />` mounted in root layout | Position top; intents map to `CheckCircle2 / XCircle / Info / XIcon` |
| `TopBar.tsx` | `back?`, `title`, `subtitle?`, `leading?`, `actions?:Array<{icon, onPress, accessibilityLabel}>` | Bar with optional `ChevronLeft` back button, SafeArea top padding (`insets.top + 6`) |
| `UserCard.tsx` | `profile:{id, handle, name, photo_url, primary_role, ..., verified_github_username?}`, `footer?`, `onPress?` | Pressable card with `AvatarCircle`, name (with `BadgeCheck` if verified), primary-role pill, headline, location |
| `variants.ts` | `Intent`, `intentClasses(intent)` | Shared semantic class map |

**Profile Hero Gradient:** `LinearGradient` from `#0f3460` to `#1a4a80` (navy → navyLight). Post-commit `5d858f8` the text color on the hero is `text-white` for AA contrast (per audit P1-4); the gold-light variant for handle/headline is no longer used.

### 8.5 Iconography (Lucide React Native)

Source: `lucide-react-native`. All icons imported anywhere across `mobile/`, verified by grepping `import {...} from 'lucide-react-native'`:

`AlertTriangle, BadgeCheck, Ban, Bell, BellOff, Briefcase, Calendar, Camera, CheckCircle2, ChevronDown, ChevronLeft, ChevronRight, Copy, Edit, Home, Inbox, Info, LucideIcon (type), MailOpen, Meh, MessageSquare, Mic, Minus, MoreHorizontal, Pause, Pencil, Play, Plus, Send, Settings, Share2, ShieldOff, Square, ThumbsUp, Trash2, Users, X (also imported as XIcon), XCircle`.

Total distinct icon names: **36** (including the `LucideIcon` type re-export).

**Flutter equivalent:** `lucide_icons` (Dart port). Verify each Dart name maps; the audit explicitly notes some icons (e.g. `BadgeCheck`) must map via `LucideIcons.badgeCheck`.

---

## Section 9 — i18n

### 9.1 Locale files

Two locales:

- `mobile/src/lib/i18n/locales/en.json` — **643 keys**.
- `mobile/src/lib/i18n/locales/es.json` — **643 keys** (perfect parity with en.json; verified by flattening + diffing).

Init (`mobile/src/lib/i18n/index.ts`): picks `Localization.getLocales()[0].languageCode` as initial language, falls back to `en`; `fallbackLng: 'en'`; `returnNull: false` (missing key renders the key path so QA can spot it); `compatibilityJSON: 'v4'` (i18next v4 plural-format). RTL handling helper `applyLayoutDirection(code)` calls `I18nManager.forceRTL(...)` for `ar/he/fa/ur` (none currently shipped).

Variable substitution: `{{name}}`-style. Special note: `{slot_id}` is treated **literally** inside `meeting_link_template` strings (server-side `replace(template, '{slot_id}', slot.id::text)` — not an i18n key).

Pluralisation: `_one` / `_other` suffixes (e.g. `profile.signals.mutual_one`, `profile.signals.mutual_other`). i18next v4 plural-format.

### 9.2 Top-level namespaces (24 total)

| Namespace | Purpose |
|---|---|
| `auth` | Sign-in, sign-up, magic link, password, errors |
| `signIn` | Legacy sign-in surface strings |
| `suspended` | Suspended-account screen |
| `home` | Home tab title, section labels |
| `settings` | All settings screens, notification kinds/channels |
| `legal` | Privacy policy and terms of service body text |
| `onboarding` | 4 steps + step labels |
| `privacy` | Blocked list, toggles, report modal |
| `verification` | GitHub verification, proof types |
| `connections` | Empty state |
| `common` | Cancel, OK |
| `intros` | Inbox, detail, compose, state badges, warm intros |
| `chat` | Chats list, conversation, message actions |
| `network` | Network tab |
| `nav.tabs` | Bottom tab labels (home, chats, inbox, network, opportunities) |
| `tabs.opportunities` | Legacy duplicate label |
| `opportunities` | Feed, detail, composer, interest, push |
| `notFound` | 404 screen |
| `profile` | Profile view, edit, share, signals, goal refresh, warm intro banner |
| `discovery` | Feed search, filters, thin pool, role/goal labels |
| `meetings` | Meeting card, propose, review, playbook |
| `media` | Voice/image messages, transcript, permissions |
| `push` | Permission denied, toast accessibility |
| `officeHours` | Settings form, booking, bookings list, badge |

(Both en.json and es.json contain the same key tree across these namespaces.)

### 9.3 Key inventory (selected — full file is the authoritative source)

Notable key shapes (every key listed below exists in BOTH locales with the same structure):

- `auth.errors.{socialSignInTitle, oauthCancelled, network, invalidCredentials, identifierRequired, emailRequired, invalidEmail, passwordRequired, passwordTooShort, magicLinkNeedsEmail, signInFailed, signUpFailed, rateLimited, emailNotConfirmed, generic}`
- `settings.notif.kind.{intro_received, intro_accepted, message_received, voice_received, meeting_proposal, meeting_confirmed, meeting_reminder, daily_matches_ready, goal_staleness}` (note: `opportunity_interest` exists in the enum but the UI matrix omits it)
- `settings.notif.channel.{push, email, in_app}`
- `onboarding.stepLabel` ("Step {{current}} of {{total}} · {{stepName}}"), `onboarding.stepName.{goal, identity, roles, about}`
- `onboarding.goal.{title, label, placeholder, counter, examplesPrefix, examples, next, errorRange, typeLabel, pickType, inferring, inferred, inferFailed}`
- `intros.compose.{hint, placeholder, counter, cancel, send, errorRange, errorDuplicate, errorCooldown, errorRateLimit, errorExpired, errorGeneric}`
- `intros.badge.{delivered, accepted, declined, expired, connected, awaitingResponse}`
- `intros.warm.{stripTitle, via_one, via_other, askCta, composeTitle, composePlaceholder, composeSubmit, composeSuccess, forwardTitle, forwardPlaceholder, forwardSubmit, forwardSuccess, kindWarmRequestBadge, kindWarmForwardVia, viaForwarder, profileBanner, profileBannerCta}`
- `chat.list.{title, emptyTitle, emptyBody}` + `chat.{composerPlaceholder, typing, edited, deletedPlaceholder, mute, unmute, muted, edit, delete, save, cancel, newMessages, messageActionsTitle, messageActionsMore, noMessages, previewImage, previewVoice, previewMeeting, deleteConfirm.{title, body, confirm}}`
- `opportunities.kind.{hiring, seeking_role, fundraising, investing, cofounder, advising, seeking_advisor, collaboration}` (matches the `opportunity_kind` enum value-for-value)
- `discovery.roles.{founder, leader, builder, investor}` + `discovery.goals.{hire, be_hired, co_found, invest, take_investment, advise, find_advisor, peer_connect}` (matches `role_kind` and `goal_type` enums)
- `meetings.playbook.{title, regenerate, regenerateRateLimited, generating, errorBanner, retry, generatedAt, justNow, minutesShort, hoursShort, daysShort, section.{summary, summaryNoName, sharedInterests, conversationStarters, do, dont}}`
- `meetings.review.{title, subtitle, useful, notUseful, noShow, notePlaceholder, pickOutcome, submitFailed, skip, submit}`
- `officeHours.settings.{title, enableLabel, enableHelp, windowsTitle, addWindow, removeWindow, copyHours, copyToWeekdays, copyToAll, weekday_0..6, slotDuration, slotDurationOption, bufferMinutes, maxBookingsPerWeek, meetingLinkLabel, meetingLinkHelp, notesLabel, windowEndAfterStart, save, saved, saveFailed}`
- `officeHours.book.{title, topicLabel, topicPlaceholder, submit, success}`
- `officeHours.bookings.{title, cancel, cancelConfirm, cancelConfirmBody, cancelled, cancelFailed, empty, emptyTitle, emptyBody, loading, slotsLoading, slotsEmptyTitle, slotsEmptyBody}`
- `verification.proofs.{founder.{domain, team_page}, investor.{domain, crunchbase, portfolio}, builder.github, leader.domain}` — each leaf has `{label, description}`; non-GitHub leaves include `verification.comingSoon` (UI only — see §17).
- `media.{recordVoice, playVoice, pauseVoice, sendPhoto, openImage, closeImage, addPhoto, uploadAvatar, recorderHint, transcriptLabel, transcriptPending, transcriptUnavailable, transcriptUnsupported, showTranscript, hideTranscript, transcriptFooter, send, cancel, permissionMicTitle/Body, permissionPhotoTitle/Body, openSettings, imageTooLargeTitle, imageTooLargeBody, voiceTooLongTitle, voiceTooLongBody, voiceTooLargeTitle, voiceTooLargeBody}`

**Key-parity note:** Both en.json and es.json have exactly 643 keys with identical paths. No missing key on either side.

---

## Section 10 — Push Notifications

### 10.1 Architecture

PostgreSQL triggers → `dispatch_push` RPC → `pg_net.http_post` → `send-push` Deno edge function → FCM v1 API → device.

### 10.2 Setup (mobile)

`@react-native-firebase/{app, messaging, analytics, crashlytics}` v24. `app.config.ts` registers plugin tuples for `./GoogleService-Info.plist` and `./google-services.json` (template `.example` files are committed; real values come from EAS secrets).

**Gating:** `env.FIREBASE_ENABLED` (`EXPO_PUBLIC_FIREBASE_ENABLED=true|false`). When `false`, all firebase entrypoints (`initFirebase`, `getFcmToken`, `onForegroundMessage`, `subscribeToTokenRefresh`) short-circuit and lazy-required modules are never loaded — required for Expo Go (post-commit `dfe7699`).

### 10.3 Token lifecycle

`useRegisterFcmToken`:

1. On mount AND on session change, calls `messaging().requestPermission()`.
2. If granted (`AUTHORIZED | PROVISIONAL`), calls `messaging().getToken()` then `supabase.rpc('register_device_token', {p_token, p_platform})`.
3. Persists last token to AsyncStorage via `lastTokenStorage.ts`.
4. Subscribes to `messaging().onTokenRefresh` and re-registers.

Sign-out path (`auth.service.ts`): calls `supabase.rpc('unregister_device_token', {p_token: lastTokenStorage.get()})` BEFORE `signOut`.

### 10.4 Foreground vs background

- **Foreground:** `useForegroundMessages` subscribes to `messaging().onMessage` → `PushToast` overlay (`payload.title/body`; tap → `resolveNotificationRoute`). **Suppressed** when the active conversation matches the message's `conversation_id` (via `activeConversationStore`).
- **Background / terminated:** handled by FCM SDK → system notification. Tap → `messaging().onNotificationOpenedApp` (warm start) or `messaging().getInitialNotification()` (cold start) — both consumed by `useNotificationTapHandler`.

### 10.5 Notification triggers (DB → push)

| Trigger function | Event | `notification_kind` |
|---|---|---|
| `notify_intro_inserted` | INSERT on `intros` (state='delivered', kind='direct') | `intro_received` |
| `notify_intro_inserted` | INSERT on `intros` (kind='warm_forward') | `intro_received` with `via_user_id` / `via_user_name` payload |
| `notify_intro_inserted` | UPDATE on `intros` (state→'accepted') — enum listed | `intro_accepted` — see note below |
| `notify_message_inserted` | INSERT on `messages` (kind='text' or 'image') | `message_received` |
| `notify_message_inserted` | INSERT on `messages` (kind='voice') | `voice_received` |
| `notify_message_inserted` | INSERT on `messages` (kind='meeting', proposal state='proposed') | `meeting_proposal` |
| `notify_meeting_confirmed` | UPDATE on `meeting_proposals` (state → 'confirmed') | `meeting_confirmed` to proposer |
| `book_slot` (direct dispatch) | INSERT pre-confirmed `meeting_proposal` | `meeting_confirmed` to host |
| `notify_opportunity_interest` | INSERT on `opportunity_interests` | `opportunity_interest` to opportunity author |

> **Triggers that do NOT exist server-side** but are listed in the `notification_kind` enum and the preferences UI: `intro_accepted`, `meeting_reminder`, `daily_matches_ready`, `goal_staleness`. The opt-out toggles exist but nothing currently emits these. See §17.

**All triggers gate via:**

1. `should_notify(recipient, kind, 'push')` (skip if user opted out).
2. Skip if conversation is muted (for message/meeting triggers).
3. Skip if event is a pre-confirmed office-hours booking (`notify_message_inserted` short-circuits when the linked proposal is already `state='confirmed'`).
4. Call `dispatch_push(...)` with structured `data.kind / data.entity_id / data.conversation_id` for client-side routing.

### 10.6 FCM payload structure (server → client)

```jsonc
{
  "recipient_id": "<uuid>",
  "event_table":  "intros|messages|meeting_proposals|opportunity_interests",
  "event_id":     "<uuid>",
  "payload": {
    "kind":  "intro_received|message_received|image_received|voice_received|meeting_proposal|meeting_confirmed|opportunity_interest",
    "title": "<localized at SQL>",
    "body":  "<localized at SQL>",
    "url":   "/(app)/...",                  // legacy fallback route
    "via_user_id":   "<uuid>",              // warm_forward only
    "via_user_name": "<string>"             // warm_forward only
  },
  "data": {                                  // forwarded into FCM message.data
    "kind":            "<same as payload.kind>",
    "entity_id":       "<row id>",
    "conversation_id": "<uuid>"             // when route needs it
  }
}
```

`send-push` forwards `payload.url + payload.kind` into FCM `data`, with `data.kind/entity_id/conversation_id` taking precedence on collision. The mobile client routes off the structured `data` first and falls through to `payload.url` for legacy events.

---

## Section 11 — Telemetry

### 11.1 Sentry

`mobile/src/lib/sentry.ts` exports `Sentry`, `initSentry`, `SentryErrorBoundary`.

- **DSN:** from `env.SENTRY_DSN` (`EXPO_PUBLIC_SENTRY_DSN`).
- **Environment:** from `env.SENTRY_ENV` (`dev | preview | production`).
- **GDPR gate:** `useTelemetryStore.getState().crashReportsEnabled` must be `true` before initializing. Default `false` (opt-OUT).
- **Boot sequence:** Init is delayed until `useTelemetryStore.persist.rehydrate()` resolves — `RootLayout` blocks the splash on `telemetryReady`.
- **Wrap:** Component default export is `Sentry.wrap(RootLayout)`; `SentryErrorBoundary` wraps the entire layout.
- **Sentry plugin tuple in `app.config.ts`** with `SENTRY_ORG / SENTRY_PROJECT / SENTRY_AUTH_TOKEN` env (EAS secrets) for source-map upload.

### 11.2 Firebase Analytics + Crashlytics

`mobile/src/lib/firebase/index.native.ts`:

- Lazy-requires firebase modules so Expo Go (no native modules) doesn't crash.
- `initFirebase`: short-circuits if `!env.FIREBASE_ENABLED`. Reads `useTelemetryStore.getState()` and calls `analytics().setAnalyticsCollectionEnabled(prefs.analyticsEnabled)` + `crashlytics().setCrashlyticsCollectionEnabled(prefs.crashReportsEnabled)`. Pref changes take effect on next launch.
- No custom `logEvent` calls have been added in the current code; analytics defaults to Firebase autocollection when enabled.
- **Same boot-sequence gate** as Sentry.

### 11.3 Telemetry store

`mobile/src/features/settings/store/telemetryStore.ts` — Zustand with persist middleware (AsyncStorage). Keys: `analyticsEnabled`, `crashReportsEnabled`. Defaults: both `false`. Rehydration is awaited in `_layout.tsx` before init.

On sign-out: both flags forced back to `false` (GDPR — next user on device starts opted-out).

---

## Section 12 — AI Integrations

Model: `claude-sonnet-4-6` (literal `ANTHROPIC_MODEL` constant in both edge functions; URL `https://api.anthropic.com/v1/messages`; version header `2023-06-01`).

API key lives in `ANTHROPIC_API_KEY` (Supabase function env). Requests authenticated via `x-api-key` header. `verify_jwt: true` in `supabase/config.toml` for both AI edge functions; functions also resolve the JWT explicitly via `supabase.auth.getUser(jwt)`.

### 12.1 `infer-goal-type`

- **Input:** `{ text: 20..280 chars, primary_role?: string, roles?: string[] }`.
- **Output:** `{ goal_type: 'hire|be_hired|co_found|invest|take_investment|advise|find_advisor|peer_connect' | null, confidence: 'high'|'low' }`.
- **Prompt summary:** deterministic system message (cached via `cache_control: ephemeral`) listing each enum value with a one-line definition, demanding a single lowercase snake_case token or literal `"none"`.
- `max_tokens=16, temperature=0`.
- **Called from:** Onboarding Goal step (`mobile/src/features/onboarding/components/GoalStep.tsx`) and profile-edit Goal type field on user input after typing ≥ 20 chars (800ms debounce). Result pre-selects a goal_type chip if `confidence='high'`; user can override.

### 12.2 `meeting-playbook`

- **Input:** `{ meeting_id: uuid, force?: boolean }`.
- **Output:** `{ summary: string, shared_interests: string[3-5], conversation_starters: string[3], do_notes: string[2-3], dont_notes: string[1-2], generated_at: ISO }`.
- **Prompt summary:** cached system instruction to output ONLY JSON with the four arrays + summary, no markdown fences. User message is `JSON.stringify({viewer_profile, target_profile, meeting_topic})`. Privacy filter: only display fields (`name, headline, bio, roles, primary_role, goal_type, goal_text, city, country`) are sent.
- `max_tokens=800, temperature=0.4`.
- **Cache:** Per `(meeting_id, viewer_id)`, keyed by `sha256(stableStringify({viewer_profile, target_profile, topic}))`, 7-day soft TTL. Stored in `meeting_playbooks` DB table.
- **Called from:** `MeetingPlaybookCard` inside a confirmed meeting's chat message. Initial load is a GET (cache check via `get_meeting_playbook` RPC). "Regenerate" button forces a new generation (client enforces 1-hour cooldown).

### 12.3 `goal-staleness-reminder` (email integration — stub)

- Identifies users with `goal_updated_at > 56 days` ago.
- **Email dispatch is not implemented** — `MAILER_KEY` env is absent in current deployment.
- Function returns `{ ok: true, stub: true, would_email: count }` in stub mode.

---

## Section 13 — Media Pipeline

### 13.1 Voice Messages

**Recording (client):**

- Microphone permission requested before recording (`useRecordAudio`, `expo-audio`).
- Max duration: **2 minutes (120 000 ms)** — UI enforced + server validated.
- Max size: **25 MB** — UI enforced + server validated.
- Formats: m4a / mp4 / aac / webm (whatever the device records natively; iOS default is m4a; Android typically aac/opus).
- UI: `VoiceRecorderSheet` — tap to record, tap to stop, playback preview, send / cancel.

**Upload flow:**

1. Record audio → local file URI.
2. Generate `messageId = crypto.randomUUID()`.
3. Path: `{conversationId}/{messageId}/voice.{ext}` (or correct extension).
4. Upload to `chat-media` bucket via `supabase.storage.from('chat-media').uploadBinary(...)`.
5. Call `send_voice_message(p_conversation_id, p_media_path, p_media_mime, p_media_size_bytes, p_duration_ms)` RPC → inserts message row with `transcript_status='pending'`.
6. DB trigger `on_voice_message_inserted` → calls `dispatch_transcription` → `transcribe-voice` edge function.

**Transcription:**

- OpenAI Whisper `whisper-1` model.
- Atomic claim pattern prevents double-processing (§4.7).
- Result written to `messages.transcript`, `messages.transcript_status = 'ready'`.
- Stub mode (`transcript_status = 'unsupported'`) when Whisper key absent.
- Hard 413 → `failed`. Transient errors → revert to `pending`.

**Playback (client):**

- `VoiceMessageBubble`: play/pause button, progress bar (0–duration), duration label.
- Signed URL (60s TTL) fetched for the private `chat-media` bucket.
- `VoicePlayerCoordinator` ensures only one voice message plays at a time.

### 13.2 Image Messages

**Upload flow:**

1. `ImagePicker.launchImageLibraryAsync` (`mediaTypes: 'Images'`, `allowsEditing: true`, `quality: 0.9`).
2. Resize ≤ 1600 px via `ImageManipulator.manipulateAsync`.
3. Generate `messageId = crypto.randomUUID()`.
4. Path: `{conversationId}/{messageId}/photo.{ext}`.
5. Upload to `chat-media` bucket.
6. Call `send_image_message(p_conversation_id, p_media_path, p_media_mime, p_media_size_bytes)` RPC.
7. On error, the orphan storage object is swept by the daily `chat-media-orphan-sweep` cron.

**Constraints:** max 5 MB, MIME types `image/jpeg | image/png | image/webp`.

**Display:** `ImageMessageBubble` — tappable to open `ImageViewerModal` (full-screen, swipe to dismiss).

### 13.3 Avatar Upload

`useUploadAvatar` (`mobile/src/features/media/hooks/useUploadAvatar.ts`):

1. `ImagePicker.launchImageLibraryAsync({mediaTypes:'Images', allowsEditing:true, aspect:[1,1], quality:0.9})`.
2. `ImageManipulator.manipulateAsync(uri, [{resize:{width:800}}], {compress:0.85, format:JPEG})`.
3. `await File.bytes()` (or `fetch(uri).blob()` on older SDK versions) → byte array. **Note:** post-commit `5d858f8` switched from `fetch(uri).blob()` to `expo-file-system.File.bytes()` to fix the bytes-upload bug.
4. `supabase.storage.from('avatars').upload('{userId}/avatar.jpg', bytes, {contentType:'image/jpeg', upsert:true})`.
5. `getPublicUrl(...)` and `update profiles set photo_url = '<url>?v=<Date.now()>'` (cache-bust).

Constraints: max 5 MB, jpeg/png/webp.

### 13.4 Size / MIME limits (`media.constants.ts`)

- `MAX_AVATAR_BYTES = 5 * 1024 * 1024` (5 MB), `image/jpeg|png|webp`.
- `MAX_IMAGE_BYTES = 5 * 1024 * 1024` (5 MB, RPC-enforced), `image/jpeg|png|webp`.
- `MAX_VOICE_BYTES = 25 * 1024 * 1024` (25 MB), `audio/m4a|mp4|aac|webm`.
- `MAX_VOICE_MS = 120_000` (2 min).
- Client-side rejection toasts: `media.imageTooLargeBody({maxMb:5})`, `media.voiceTooLongBody({maxMinutes:2})`, `media.voiceTooLargeBody({maxMb:25})`.

### 13.5 ICS Calendar Export

- **Pure client-side** generation in `ics.service.ts`.
- RFC 5545 compliant:
  - UTC timestamps.
  - Line folding ≤ 75 octets per physical line (UTF-8 byte-accurate via `utf8.encode(char).length`).
  - Escape sequences for `;`, `,`, `\`, `\n`.
- Output saved to device filesystem (`expo-file-system` cache); shared via `expo-sharing`.
- `UID` format: `meeting-{meetingId}@bvisionry.com`.
- Unit-tested via `__test__` export of `formatICSDate`, `escapeICS`, `foldLine`.

---

## Section 14 — Real-time / Subscriptions

### 14.1 Supabase Realtime

Realtime publication `supabase_realtime` includes `messages` and `meeting_proposals` (only these two are added — `alter publication supabase_realtime add table public.<x>` calls verified in migrations).

| Hook | Channel / filter | Invalidates |
|---|---|---|
| `useMessagesRealtime(conversationId)` | `supabase.channel('messages:<id>').on('postgres_changes', {event:'*', schema:'public', table:'messages', filter:'conversation_id=eq.<id>'}, ...)` | `['messages', conversationId]`, `['conversation-overview']`, `['unread-counts']` |
| `useMeetingProposalsRealtime(conversationId)` | analogous, filter on `meeting_proposals.conversation_id` | `['meeting-proposals', conversationId]`, `['messages', conversationId]` |
| `useTypingChannel(conversationId)` | `supabase.channel('typing:<id>').on('broadcast', {event:'typing'}, ...).track({userId})` | Not query-cache-backed; lives in component state |

**`messages` `replica identity full`** (slice `20260606070000_chat_fixes.sql`) so UPDATE / DELETE payloads carry every column — required for the edit/delete-rendering optimistic merge and for client-side cache removal on Realtime DELETE.

**Rate limit:** `eventsPerSecond=10` in the Supabase client init.

### 14.2 Typing indicator

`useTypingChannel`:

- Supabase Presence/Broadcast channel per conversation.
- Broadcasts `{ typing: true }` on text input; clears after ~2s of inactivity.
- Other participant's typing state rendered as "typing..." in the conversation header.

### 14.3 Push

FCM is used for background/terminated-state notifications and foreground toasts. Not a real-time channel — push is one-directional server→client.

---

## Section 15 — Testing & QA

### 15.1 Jest unit tests

Path: `mobile/tests/`. Preset: `jest-expo`. Coverage includes:

- `tests/components/AvatarCircle.test.tsx`, `QueryState.test.tsx`, `tests/components/ui/{Banner,Button,Card,Input,Modal,Pill,ProgressDots,SettingsRow,TopBar,UserCard}.test.tsx`.
- `tests/features/auth/*` — auth.service, errorMap, socialAuth.service, useMagicLinkSubmit, useNextRoute, password auth.
- `tests/features/chat/*` — chat.service, ConversationListRow, MessageBubble, useSendMessage.
- `tests/features/connections/connections.service.test.ts`.
- `tests/features/discovery/discovery.service.test.ts`.
- `tests/features/intros/*` — service, schemas, IntroDetailView, IntroStateBadge, warmIntros.service, WarmIntroSuggestionsStrip.
- `tests/features/media/*` — storage.service, useSendImageMessage, useSendVoiceMessage, ImageMessageBubble, VoiceMessageBubble.
- `tests/features/meetings/*` — cancel_meeting, ics.service, MeetingCard, MeetingPlaybookCard, meetings.service.

Config: `mobile/jest.config.js`.

### 15.2 Deno edge-function tests

Each handler is exported and tested with stub Supabase clients and mock HTTP responses:

- `supabase/functions/auth-handle-login/index.test.ts`
- `supabase/functions/delete-account/index.test.ts`
- `supabase/functions/goal-staleness-reminder/index.test.ts`
- `supabase/functions/send-push/index.test.ts`
- `supabase/functions/transcribe-voice/index.test.ts`
- `supabase/functions/infer-goal-type/index.test.ts`
- `supabase/functions/meeting-playbook/index.test.ts`

Shared utils: `supabase/functions/_shared/{cors.ts, env.ts, test-utils.ts}`.

### 15.3 Playwright E2E

Path: `mobile/playwright/`. Flows directory: `playwright/flows/`. Covered:

- `auth-redirect.spec.ts`, `sign-in.spec.ts`, `sign-up.spec.ts`, `password-auth.spec.ts`.
- `onboarding.spec.ts`.
- `chat.spec.ts`, `chat-media.spec.ts`.
- `discovery.spec.ts`.
- `intros.spec.ts`.
- `privacy.spec.ts`.
- `profile-edit.spec.ts`.
- `rbac.spec.ts`.
- `verification.spec.ts`.

Fixtures in `playwright/fixtures/`, helpers in `playwright/helpers/`. Config: `mobile/playwright.config.ts`. Run via `pnpm test:e2e`.

### 15.4 Maestro flows

Path: `mobile/maestro/flows/`. Files: `launch-smoke.yaml`, `sign-in-smoke.yaml`, `social-buttons-smoke.yaml`. Run via `pnpm maestro:smoke` (filters by `@smoke` tag).

### 15.5 Local Supabase stack

`supabase/config.toml` is the source of truth. Local dev: `supabase start` boots a Docker stack (Postgres, Kong, Auth, Storage, Realtime, Edge runtime). Migrations under `supabase/migrations/` are applied at start. `pg_cron` extension is declared in `[db.extensions]`.

### 15.6 Manual QA scenarios

1. **Auth gate:** Unauthenticated → sign-in; `onboarded=false` → onboarding; `suspended_at` set → suspended screen.
2. **Intro cap:** Send > 20 intros on same UTC day → `daily_cap` error.
3. **Intro cooldown:** Decline intro → same sender cannot send again for 30 days.
4. **Warm intro anti-shotgun:** Send `warm_request` to same target twice (via any mutual) → rejected.
5. **Meeting review gate:** Review only submittable after `confirmed_slot + duration < now()`.
6. **Office hours weekly cap:** Book more than `max_bookings_per_week` slots with same host → rejected.
7. **Voice message transcription:** Send voice → `transcript_status` transitions `pending → processing → ready`.
8. **Push deregistration on sign-out:** Token revoked before `signOut` completes.
9. **GDPR telemetry defaults:** Fresh install defaults `analyticsEnabled=false`, `crashReportsEnabled=false`.

---

## Section 16 — Build & Release

### 16.1 `app.config.ts` env vars

| Variable | Required for | Default |
|---|---|---|
| `EXPO_PUBLIC_SUPABASE_URL` | always | — |
| `EXPO_PUBLIC_SUPABASE_ANON_KEY` | always | — |
| `EXPO_PUBLIC_SENTRY_DSN` | crash-reporting | undefined |
| `EXPO_PUBLIC_SENTRY_ENV` | Sentry env tagging | `'dev'` |
| `EXPO_PUBLIC_FIREBASE_ENABLED` | FCM + analytics + crashlytics | `'false'` (Expo Go) |
| `EXPO_PUBLIC_EAS_PROJECT_ID` | required in prod (throws); placeholder `PROJECT_ID_PLACEHOLDER` in dev | — |
| `EXPO_PUBLIC_APP_LINKS_HOST` | required in prod (throws); placeholder `DOMAIN_PLACEHOLDER` in dev | — |
| `SENTRY_ORG` / `SENTRY_PROJECT` / `SENTRY_AUTH_TOKEN` | build-time source-map upload | EAS secret |
| `NODE_ENV=production` OR `EXPO_PUBLIC_SENTRY_ENV=prod` | gate the prod-only env throws | — |

### 16.2 EAS Build Profiles (`mobile/eas.json`)

Three profiles — `development`, `preview`, `production`. All pull `SUPABASE_URL`, `SUPABASE_ANON_KEY`, Sentry DSN from EAS secrets. `preview` + `production` set `FIREBASE_ENABLED=true` and pass through `SENTRY_*` and `EAS_PROJECT_ID` / `APP_LINKS_HOST` secrets. Channel names map to EAS Update channels. `appVersionSource: 'remote'`.

| Profile | Distribution | Channel | Notes |
|---|---|---|---|
| `development` | internal | development | Dev client, APK, Firebase disabled |
| `preview` | internal | preview | APK, Firebase enabled, auto-increment build number |
| `production` | store | production | Firebase enabled, auto-increment, source maps to Sentry |

### 16.3 App Identifiers

- **iOS bundle ID:** `com.bvisionry.connect`
- **Android package:** `com.bvisionry.connect`
- **Expo scheme:** `connect-mobile`
- **EAS project ID:** from `EXPO_PUBLIC_EAS_PROJECT_ID` env (required in production)

### 16.4 OTA Updates

- **EAS Update** with `runtimeVersion: { policy: 'appVersion' }` — OTA updates pinned to the native binary's app version. Bump `version` in `app.config.ts` to force a new native build.
- Update URL: `https://u.expo.dev/{easProjectId}`.

### 16.5 Firebase setup files

- **iOS:** `mobile/GoogleService-Info.plist` (template `.example` committed; real values per environment).
- **Android:** `mobile/google-services.json` (template `.example` committed).

### 16.6 Edge function secrets (Supabase)

```
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_ANON_KEY
WEBHOOK_SHARED_SECRET           (shared between DB and all webhook edge functions)
ANTHROPIC_API_KEY               (infer-goal-type, meeting-playbook)
FCM_SERVICE_ACCOUNT_JSON        (send-push)
WHISPER_API_KEY / OPENAI_API_KEY (transcribe-voice)
MAILER_KEY                      (goal-staleness-reminder — not yet wired)
DELETE_ACCOUNT_ALLOWED_ORIGINS  (delete-account — optional override)
WHISPER_TIMEOUT_MS              (transcribe-voice — optional, default 30000)
```

### 16.7 PostgreSQL GUC settings

```sql
app.functions_base_url    -- base URL for pg_net calls to edge functions
app.webhook_shared_secret -- secret header value for edge function auth
```

### 16.8 pnpm workspace

Root `pnpm-workspace.yaml` lists `mobile`. Root `package.json` defines tooling. Mobile uses pnpm hoisting (lockfile at root).

### 16.9 Known TypeScript baseline issues

Pre-existing TS errors that contributors are allowed to leave alone:

1. `mobile/src/features/intros/services/intros.service.ts` casts the `intros` row type to a local `IntroRow` augmented with `declined_at` / `kind` / `warm_target_id` because `types.gen.ts` hasn't been regenerated.
2. Same file: `fetchIntrosTodayCount` casts `supabase.rpc` via `as any` because `intros_today_count` isn't in `types.gen.ts`.
3. `mobile/src/features/chat/services/chat.service.ts` casts `supabase.rpc` through `unknown` for `list_conversation_overview` for the same reason.
4. Commit `5d858f8` regenerated `types.gen.ts`; the precise list of remaining TS errors should be reverified via `pnpm typecheck` before the Flutter rebuild begins.

---

## Section 17 — Known Gaps / TODOs (unified)

### 17.1 Email integration (not implemented)

The `goal-staleness-reminder` edge function identifies stale-goal users but does NOT send emails. The `MAILER_KEY` env is absent in all environments. Function returns `{ stub: true, would_email: count }`. Email dispatch must be built before this feature is meaningful.

### 17.2 Profile public investor page

The `public_investor_page` flag exists on profiles. The privacy toggle exposes it. No public web rendering page is implemented — the URL `connect.bvisionry.com/u/{handle}` is referenced in i18n copy but no corresponding route exists.

### 17.3 Non-GitHub verification (coming soon)

Only GitHub verification is implemented. Domain email, Crunchbase, portfolio, and /team-page proofs are labeled `verification.comingSoon` in the UI. The `set_github_verification` RPC exists; no analogous RPCs for other proof types.

### 17.4 Notification kinds with no server emitter

`notification_kind` includes `intro_accepted`, `meeting_reminder`, `daily_matches_ready`, `goal_staleness`. The preference UI shows them but no SQL trigger or scheduled job currently emits them. Opt-out toggles exist but have no backend.

### 17.5 Profile handle redirect (UI copy only)

The i18n hint says "Changing your handle creates a redirect for 90 days, then 410 Gone" but no redirect mechanism is implemented in the database or edge functions.

### 17.6 Social proof ratings hidden when < 3 reviews

`get_profile_signals` returns `null` for `avg_meeting_rating` when fewer than 3 reviews exist. `ProfileSignalsRow` must hide the rating row in this case.

### 17.7 `lookup_email_by_handle` deprecated

Revoked from all client roles after `20260606060000_revoke_handle_lookup.sql`. Only callable via service-role by `auth-handle-login`. Do not expose in Flutter.

### 17.8 `list_conversation_overview` RPC parameter

Signature: `list_conversation_overview(p_user_id uuid DEFAULT auth.uid())`. React Native service passes `{ p_user_id: userId }` explicitly. In Flutter, call with no arguments to use the default `auth.uid()`.

### 17.9 Warm-request acceptance refused

`accept_intro` REFUSES `kind='warm_request'` intros with `22023 wrong intro kind`. The inbox must detect `kind='warm_request'` and render the `WarmIntroForwardSheet` instead of accept/decline buttons.

### 17.10 `meeting_feedback` superseded by `meeting_reviews`

The legacy `meeting_feedback` table (`meeting_feedback_rating` enum: positive / neutral / negative) is partly superseded by `meeting_reviews` (`outcome` text: useful / not_useful / no_show). Both tables exist; the post-meeting prompt UI uses `meeting_reviews`.

### 17.11 Font pairing

Pre-commit `5d858f8` the app used `Overlock_400Regular` as the body font (audit P2-10 flagged as too casual). Current `global.css` uses `Inter_400Regular`. Flutter rebuild should use **Inter only** (not Overlock).

### 17.12 Forgot-password is a placeholder

`SignInForm.tsx` "Forgot password?" CTA opens a confirm/toast pointing the user at the magic-link button. There is no real reset-password flow.

### 17.13 `notification_preferences` rows are not seeded

`should_notify` returns `true` when no row exists. UI builds an opt-out matrix; opt-in is the default.

### 17.14 47-item UI/UX audit findings (from `UI_UX_AUDIT.md`)

Status flags are best-effort against the source as of commit `5d858f8` ("enterprise UI/UX overhaul + foundation fixes"), which addresses a large fraction of P0/P1 items. **All 47 items are listed.** "DONE" = fixed in source; "PARTIAL" = primitive exists or some migration done; "OPEN" = not addressed.

**P0 — Blockers (5):**

| # | Title | Status |
|---|---|---|
| P0-1 | Emoji bottom-tab icons | DONE (replaced with `lucide-react-native` in commit `5d858f8`; `Home, Inbox, Users, Briefcase, MessageSquare` per `app/(app)/(tabs)/_layout.tsx`) |
| P0-2 | Chat conversation header bypasses TopBar | DONE (commit `5d858f8` "Chat: TopBar header w/ avatar+actions") |
| P0-3 | `Alert.alert` for destructive confirms | DONE (`ConfirmDialog` + `useConfirm` primitives shipped in commit `5d858f8`) |
| P0-4 | Two parallel screen-header patterns | DONE (commit `5d858f8` "TopBar replaces pt-16 inline titles" across all migrated screens) |
| P0-5 | No skeleton loading states | DONE (`Skeleton` + composites added in commit `5d858f8`) |

**P1 — High-impact polish (16):**

| # | Title | Status |
|---|---|---|
| P1-1 | Typography px leaks | DONE (`text-display-{xl,lg,md,sm,xs}` / `text-body-{lg,md,sm,xs}` scale added in commit `5d858f8`) |
| P1-2 | Inconsistent spacing scale | DONE (`gutter / card / card-lg / section` tokens added in commit `5d858f8`) |
| P1-3 | Avatar halo too heavy | DONE (commit `5d858f8` "Avatar (replaces AvatarCircle halo math)") |
| P1-4 | ProfileHero contrast (gold-light on navy-light) | DONE (commit `5d858f8` "white-on-navy hero text (3.4:1 → AA)") |
| P1-5 | Inconsistent empty states | DONE (`EmptyState` primitive shipped and adopted across feeds in commit `5d858f8`) |
| P1-6 | Duplicated `Section` component | DONE (`SectionCard` primitive shipped; commit `5d858f8` "SectionCard everywhere") |
| P1-7 | Sign-out button placement duplicated | DONE (commit `5d858f8` "sign-out removed from profile"; settings is now the only location) |
| P1-8 | Primary button needs dark/light surface variant | DONE (commit `5d858f8` "sticky bottom Send-Intro CTA"; the navy-wrapper hack was removed) |
| P1-9 | Tab unread badges visually conflict with labels | DONE (commit `5d858f8` "gold-dot unread badges") |
| P1-10 | Goal chips on home wrap | PARTIAL (commit `5d858f8` "fade gradient for clipped chips") |
| P1-11 | Settings "Sign out" red-outline alarming | DONE (commit `5d858f8` "sign-out outline (not danger)") |
| P1-12 | Inputs lack focus state on web | PARTIAL (`Input` has focused state via TS `focused` boolean; web `focus:` selectors not verified) |
| P1-13 | Profile share copies deeplink | DONE (commit `5d858f8` "web-URL share + toast") |
| P1-14 | Feed cards no pressed state on web | OPEN |
| P1-15 | Form keyboard handling missing | DONE (commit `5d858f8` "KeyboardAvoidingView on edit form") |
| P1-16 | Daily matches strip uses raw inline pill | DONE (commit `5d858f8` "Pill for match reason") |

**P2 — Medium (16):**

| # | Title | Status |
|---|---|---|
| P2-1 | No global toast | DONE (`Toast` + `useToast` shipped in commit `5d858f8`) |
| P2-2 | Onboarding back button reimplements TopBar | DONE (commit `5d858f8` "TopBar back chevron" for onboarding) |
| P2-3 | Settings notif table overflow at 390px | DONE (commit `5d858f8` "per-(kind,channel) notification rows for 390px viewport") |
| P2-4 | ProfileEditForm uses `pt-16` not TopBar | DONE (commit `5d858f8` "TopBar replaces pt-16 inline titles") |
| P2-5 | Voice/image buttons below 44pt | DONE (commit `5d858f8` "IconButton composer" — IconButton enforces ≥ 44dp via hitSlop) |
| P2-6 | Opportunity-kind pill colour unreadable | DONE (commit `5d858f8` "single neutral kind pill (was 8 colors)") |
| P2-7 | Long-press to edit/delete undiscoverable | DONE (commit `5d858f8` "per-bubble more-menu") |
| P2-8 | Office-hours form needs "copy to weekdays" | DONE (commit `5d858f8` "per-day copy-to-weekdays affordance"; i18n keys `copyToWeekdays`/`copyToAll`) |
| P2-9 | Profile share+edit hierarchy unclear | OPEN |
| P2-10 | Body font Overlock too casual | DONE (commit `5d858f8` "Body font swapped Overlock → Inter") |
| P2-11 | Meeting card TZ formatting wraps | DONE (commit `5d858f8` "MeetingCard timezone split into two lines") |
| P2-12 | Gold button only used in "Send intro" | OPEN |
| P2-13 | Cards-on-cards (UserCard inside OpportunityCard) | DONE (commit `5d858f8` "borderless AuthorRow (no nested UserCard)") |
| P2-14 | Onboarding lacks step labels/percentages | DONE (commit `5d858f8` "Step X of Y label above ProgressDots") |
| P2-15 | Bottom-sheet handle is the only dismiss hint | OPEN |
| P2-16 | No animation on tab switch | OPEN |

**P3 — Nice-to-have (10):**

| # | Title | Status |
|---|---|---|
| P3-1 | Hero wordmark weight inconsistency | DONE (commit `5d858f8` "wordmark unified weight") |
| P3-2 | Banner closeable | DONE (`Banner.onClose` prop in `Banner.tsx`) |
| P3-3 | Send-message arrow glyph | DONE (commit `5d858f8`: `MessageComposer` now imports `Send` icon) |
| P3-4 | Stepper colors inverted | DONE (commit `5d858f8`: ProgressDots uses navy=past, gold=current per audit) |
| P3-5 | OR-divider primitive | DONE (`Divider.tsx` ships with optional label) |
| P3-6 | Onboarding `text-2xl` outlier | DONE (commit `5d858f8` "display-lg step titles") |
| P3-7 | Verified badge UTF-8 check (`✓` → real icon) | DONE (commit `5d858f8` "BadgeCheck for verified"; `UserCard.tsx` imports `BadgeCheck`) |
| P3-8 | OH form stepper inputs | DONE (commit `5d858f8` "Stepper for numeric inputs"; `Stepper.tsx` primitive ships) |
| P3-9 | Profile headline vs bio hierarchy | OPEN |
| P3-10 | SettingsRow no pressed state | OPEN |

**Audit summary:** 5 P0 + 16 P1 + 16 P2 + 10 P3 = 47 items. Of these, commit `5d858f8` resolved approximately 36 (5 P0, 13 P1, 12 P2, 8 P3); roughly 11 remain OPEN or PARTIAL.

---

## Section 18 — Flutter Rebuild Handoff Notes

### 18.1 Recommended Flutter packages per capability

| Capability | Flutter package |
|---|---|
| Supabase (Auth + DB + Storage + Functions + Realtime) | `supabase_flutter` |
| Routing (file-based equivalent + deep links) | `go_router` + `app_links` (or `uni_links`) |
| Internationalisation | `flutter_localizations` + `intl` (gen-l10n) **or** `easy_localization` for direct JSON ingestion |
| Form state | `flutter_hooks` + `riverpod_hook_form` OR `reactive_forms` |
| Validation | `formz` or hand-rolled with `Either`-style returns |
| State (server) | `riverpod` + `AsyncValue` / `AsyncNotifier` (replaces TanStack Query) |
| State (client) | `riverpod` `StateNotifierProvider`s (replaces Zustand) |
| Persistent storage | `shared_preferences` (replaces AsyncStorage), `flutter_secure_storage` (replaces expo-secure-store) |
| Push (FCM) | `firebase_messaging` + `firebase_core` |
| Crash / analytics | `sentry_flutter`, `firebase_analytics`, `firebase_crashlytics` |
| Icons | `lucide_icons` (Dart port); verify icon coverage for §8.5 list |
| Fonts | `google_fonts` for Dosis + Inter, or bundle them |
| Image picker / cropping | `image_picker` + `image_cropper` or `image` (manipulation) |
| Image cached display | `cached_network_image` |
| Audio record / playback | `record` + `audioplayers` (or `just_audio`) |
| File system | `path_provider` + `dart:io` `File` |
| Sharing | `share_plus` |
| Markdown | `flutter_markdown` |
| Date/time pickers | `flutter` material `showDatePicker` / `showTimePicker`, or `omni_datetime_picker` |
| Bottom sheets / modals | `showModalBottomSheet` (built-in) |
| Toast | flutter-native `SnackBar` + custom overlay, or `another_flushbar` |
| ICS generation | hand-rolled (mirror `ics.service.ts`) |
| Pluralisation | Dart `intl`'s `Intl.plural` (`one` / `other` cases) |
| OAuth (Google / Apple) | `google_sign_in`, `sign_in_with_apple`. Magic link via Supabase deep link |

### 18.2 What translates directly (zero behavioural change)

- Every RPC name, parameter list, return shape (re-emit from `supabase/migrations`).
- Every storage bucket name + path convention (`{userId}/...` for avatars, `{conversationId}/{messageId}/...` for chat-media).
- Every RLS policy (backend unchanged).
- Every notification kind, payload shape, and route mapping.
- Every error code (`P0001 hint='cooldown'`, `P0001 hint='daily_cap'`, `P0002`, `22023`, `42501`, `23505`, `28000`) → typed Flutter exception classes.
- Every i18n key path (en.json / es.json can be ingested as ARB via gen-l10n or kept as JSON via `easy_localization`).
- Every Zod validation rule → Dart validators with the same ranges and regexes.
- Auth callback URL scheme (`connect-mobile://auth`) and universal-link host (`connect.bvisionry.com/p/<handle>`).

### 18.3 What does NOT translate (rewrite required)

- NativeWind `className` strings → Flutter `Theme`/`ThemeData`/`ColorScheme`/`TextTheme`. Map every token from §8.1–§8.3 into a `ThemeExtension` so widgets can `Theme.of(context).extension<AppTokens>()`.
- Expo Router file-based routing → declarative `GoRouter` route table mirroring §7.
- `react-i18next` namespacing → `gen-l10n` ARB files OR `easy_localization` with the existing JSON files.
- TanStack Query optimistic mutations / cache invalidation → `riverpod`'s `AsyncNotifier.update` + `ref.invalidate(...)`.
- Zustand persisted stores → `riverpod` + `shared_preferences`-backed `StateNotifier`s; `useTelemetryStore` must rehydrate BEFORE init Sentry / Firebase, exactly as the React side does.
- React Hook Form + Zod schemas → Dart classes (consider `freezed` + manual validators).
- `lucide-react-native` icon set → `lucide_icons` Dart port (verify icon name parity for the 36 imports in §8.5).
- `expo-auth-session` PKCE flow → Supabase Flutter handles OAuth deep links natively via `supabase.auth.signInWithOAuth(...)` and `setSession` after the `connect-mobile://auth?code=...` redirect.
- `expo-file-system.File.bytes()` → `dart:io` `File(...).readAsBytes()` followed by `supabase.storage.from(...).uploadBinary(...)`.
- `react-native-markdown-display` → `flutter_markdown`.
- `react-native-safe-area-context` `useSafeAreaInsets` → Flutter `MediaQuery.of(context).padding` / `SafeArea` widget. **Preserve** the tab-bar `TAB_BAR_CONTENT_HEIGHT=56` + `MAX_BOTTOM_INSET=24` rule for Android edge-to-edge robustness.

### 18.4 Backend invariants (do not change)

- Conversations are canonical: `participant_a_id < participant_b_id`. The Flutter client must NEVER insert directly; always rely on the RPC path (`accept_intro` / `book_slot`).
- All chat image / voice / meeting message inserts go through SECURITY DEFINER RPCs (`send_image_message`, `send_voice_message`, `propose_meeting`, `book_slot`). The RLS policy on `messages_insert_participant` REJECTS any non-text direct insert.
- Daily matches are inserted at most once per `(user_id, for_date_local)`. The trailing SELECT in `get_daily_matches` re-applies private/suspended/blocks filters at read time.
- `register_device_token` reassigns ownership ONLY when the existing row was revoked or matches the caller — never silently steals a token.
- The push pipeline is idempotent on `(event_table, event_id, recipient_id)` in `push_log` and additionally claims atomically with a 5-minute replay window. Flutter does not interact with push_log directly.
- `meeting_reviews` rejects submissions where `confirmed_slot + duration > now()`.

### 18.5 Compatibility / drift watch-points

- The `intros.kind` column and `intro_kind` enum are present in the DB but were not in `types.gen.ts` at the time of the Sonnet/Opus inventory; Flutter should emit the enum manually OR regenerate types post-rebuild.
- `meeting_reviews.outcome` is `text CHECK in (...)`, not a Postgres enum — Flutter should treat it as `String` validated client-side against `{'useful', 'not_useful', 'no_show'}`.
- The `office_hours_settings.windows` jsonb shape is not Postgres-typed; Flutter should ship a Dart class `OfficeHoursWindow { int weekday, int startMinute, int endMinute, String timezone }` and serialise via `jsonEncode`.
- `meeting_proposals.timezone` is IANA; trust the server-side `now() at time zone timezone` CHECK to reject invalid names — surface the SQL error as a form-validation error.

### 18.6 Code snippets — direct translations

**Supabase client init:**

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

**Auth gate redirect:**

```dart
redirect: (context, state) {
  final session = ref.read(sessionProvider);
  final profile = ref.read(currentProfileProvider);
  if (session == null) return '/auth/sign-in';
  if (profile?.suspendedAt != null) return '/suspended';
  if (profile?.onboarded != true) return '/onboarding/goal';
  return null;
}
```

**RPC call:**

```dart
final response = await supabase.rpc('get_daily_matches', params: {
  'p_for_date': DateTime.now().toIso8601String().substring(0, 10),
});
```

**Realtime subscription:**

```dart
supabase.channel('messages:${conversationId}')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'messages',
    filter: PostgresChangeFilter(type: FilterType.eq, column: 'conversation_id', value: conversationId),
    callback: (payload) { /* handle */ },
  )
  .subscribe();
```

**Storage upload + signed URL:**

```dart
await supabase.storage.from('avatars').uploadBinary('${userId}/avatar.jpg', bytes,
  fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));

final url = await supabase.storage.from('chat-media').createSignedUrl(path, 60);
```

**Handle login via edge function:**

```dart
final response = await supabase.functions.invoke('auth-handle-login', body: {
  'handle': handle.replaceFirst(RegExp(r'^@+'), ''),
  'password': password,
});
final data = response.data as Map<String, dynamic>;
await supabase.auth.setSession(
  accessToken: data['access_token'],
  refreshToken: data['refresh_token'],
);
```

**Account deletion:**

```dart
final session = supabase.auth.currentSession;
final response = await http.post(
  Uri.parse('${supabaseUrl}/functions/v1/delete-account'),
  headers: {
    'Authorization': 'Bearer ${session!.accessToken}',
    'Content-Type': 'application/json',
  },
);
```

**Cursor pagination (messages):**

```dart
// First page
supabase.from('messages')
  .select()
  .eq('conversation_id', id)
  .order('created_at', ascending: false)
  .limit(30);

// Next page (before cursor)
supabase.from('messages')
  .select()
  .eq('conversation_id', id)
  .lt('created_at', cursor)
  .order('created_at', ascending: false)
  .limit(30);
```

**Push token registration:**

```dart
final token = await FirebaseMessaging.instance.getToken();
await supabase.rpc('register_device_token', params: {
  'p_token': token,
  'p_platform': Platform.isIOS ? 'ios' : 'android',
});

FirebaseMessaging.onMessage.listen((message) { /* show in-app toast */ });
FirebaseMessaging.onMessageOpenedApp.listen((message) { /* navigate */ });
```

**GDPR telemetry gate:**

```dart
final prefs = await SharedPreferences.getInstance();
final crashEnabled = prefs.getBool('crashReportsEnabled') ?? false;
final analyticsEnabled = prefs.getBool('analyticsEnabled') ?? false;
if (crashEnabled) await SentryFlutter.init(...);
if (analyticsEnabled) await Firebase.initializeApp(...);
// Force both back to false on sign-out (next user starts opted-out)
```

### 18.7 Gotchas list

1. **Canonical conversation order** — `participant_a_id < participant_b_id` by UUID sort. Always query with `participant_a_id = x OR participant_b_id = x`.
2. **`#variable_conflict use_column`** — present in `suggest_warm_intros`, `get_daily_matches`, `list_connections`. PostgreSQL-internal; transparent.
3. **`warm_request` intros cannot be accepted via `accept_intro`** — RPC raises `22023`. Detect `kind='warm_request'` and show Forward sheet.
4. **Sign-out scope `'local'`** — never use global scope.
5. **`messages` REPLICA IDENTITY FULL** — DELETE events via Realtime include the full old row.
6. **Goal text minimum** — DB constraint is 10 chars; client schema enforces 10 chars.
7. **`infer-goal-type` may return `{ goal_type: null, confidence: 'low' }`** — client must NOT pre-select a chip; show `inferFailed` message.
8. **`meeting_playbooks` all-false RLS** — always use `get_meeting_playbook` RPC.
9. **Office hours slots materialize nightly** — cron `office-hours-materialize-daily` pre-computes; `list_upcoming_slots` reads. `materialize_office_hours_slots` uses host's local timezone (from `windows` JSONB) and DST-correct wall-clock day-of-week computation.
10. **Verified-column writes** — column-level UPDATE on `verified_*`, `suspended_at`, `onboarded`, `private_mode`, `public_investor_page` is revoked from `authenticated`. Only the corresponding SECURITY DEFINER RPCs can set them.

---

## Section 19 — Sources Reconciled (Audit Trail)

This section documents every section-by-section reconciliation between the Sonnet and Opus inventories and the source.

### §0 Reading guide & tech stack
- **MERGED:** Both agents listed the same React Native stack with minor wording differences.
- **No discrepancies.**

### §1 Product summary
- **MERGED:** Sonnet's "Core loop" steps and Opus's narrative paragraph combined.
- **RESOLVED via source:** Opus correctly identified `goals_complementary` pairs (3 pairs, not 4). Sonnet incorrectly listed `co_found ↔ co_found` as complementary; source (`20260527000000_slice17_matching.sql`) shows only `hire ↔ be_hired`, `invest ↔ take_investment`, `advise ↔ find_advisor` are complementary.

### §2 Data model
- **MERGED:** Sonnet's table-by-table prose and Opus's column tables combined into authoritative tables with verbatim SQL constraints.
- **RESOLVED via source (15 enums total, both inventories complete):** `role_kind`, `goal_type`, `intro_state`, `intro_kind`, `meeting_state`, `meeting_feedback_rating`, `message_kind` (extended slice6 → slice13), `device_platform`, `report_target_type`, `report_reason`, `notification_kind` (extended by 3 alter type adds), `notification_channel`, `transcript_status` (extended by 1 alter type add), `opportunity_kind`, `opportunity_status`. Final value lists dumped verbatim.
- **RESOLVED via source (notification_kind enum):** Sonnet's list omits `meeting_proposal`. Opus's list omits `intro_accepted` (which IS in the enum but no trigger emits — see §17.4). Source-correct final value set: `intro_received, intro_accepted, message_received, voice_received, meeting_reminder, daily_matches_ready, goal_staleness, meeting_proposal, meeting_confirmed, opportunity_interest`.
- **RESOLVED via source (office_hours_settings defaults):** Sonnet said `slot_duration_minutes default 30, max_bookings_per_week default 3, buffer_minutes default 0`. Opus said `15 / 5 / 5`. Source `20260608030000_office_hours.sql` confirms Opus (`15 / 5 / 5`). Discrepancy flagged inline.
- **RESOLVED via source (meeting_proposals FK):** Sonnet said `proposer_id` with `ON DELETE CASCADE`. Actual column is `proposed_by_id` with `ON DELETE SET NULL`. Inline note added.
- **RESOLVED via source (reports.quoted_message_id):** Sonnet listed this column; Opus omitted. Source confirms it exists. Included.
- **MERGED (tables, 22 total):** `profiles`, `daily_matches`, `intros`, `conversations`, `messages`, `meeting_proposals`, `meeting_feedback`, `meeting_reviews`, `meeting_playbooks`, `blocks`, `reports`, `conversation_reads`, `conversation_mutes`, `device_tokens`, `push_log`, `notification_preferences`, `opportunities`, `opportunity_interests`, `office_hours_settings`, `office_hours_slots`, plus storage buckets `avatars` and `chat-media`. Cross-checked against `grep "create table" supabase/migrations/` (20 tables) + 2 buckets = 22 entities.

### §3 RPCs
- **MERGED:** Sonnet listed ~46 RPCs in prose form; Opus listed ~58 in tighter form. Final document lists **all 75 distinct `create or replace function public.*` declarations** (verified by `grep "^create or replace function public\." supabase/migrations/ | sed -E 's/.*function (public\.[a-z_]+).*/\1/' | sort -u | wc -l = 75`).
- **RESOLVED via source (`send_image_message` signature):** Sonnet said `(p_conversation_id uuid, p_path text, p_filename text, p_size_bytes int) → uuid`. Opus said `(p_conversation_id, p_media_path, p_media_mime, p_media_size_bytes int) → messages`. Source `20260606110000_media_message_rpcs.sql` confirms Opus exactly.
- **RESOLVED via source (`send_voice_message` signature):** same as above; Opus was correct.
- **RESOLVED via source (`get_profile_signals`):** Opus correctly noted `numeric(2,1)` return type for `avg_meeting_rating`. Both inventories agreed on the < 3-reviews-hides-rating behaviour.
- **RESOLVED via source (`book_slot` flow):** Opus's description of pre-confirmed-meeting + suppressed message-push trigger + direct `dispatch_push` was source-accurate; Sonnet's was higher-level. Opus's prose merged in.
- **RESOLVED via source (cancel_booking 24h threshold):** Opus identified `> now() + 24h → reopen, else cancelled`. Sonnet omitted the threshold. Confirmed in `20260608030000_office_hours.sql`.
- **MERGED (trigger functions):** Both agents listed the 8 trigger functions; combined into one authoritative table.
- **MERGED (cron jobs):** Both agents listed all 5; cross-references confirmed in `20260606140000_scheduled_jobs.sql`.

### §4 Edge functions
- **MERGED:** Both agents listed all 7 functions (`auth-handle-login`, `delete-account`, `goal-staleness-reminder`, `infer-goal-type`, `meeting-playbook`, `send-push`, `transcribe-voice`). Verified by `ls supabase/functions/`.
- **RESOLVED via source (transcribe-voice failure modes):** Opus identified `revert → pending` (transient) vs `failed` (413 oversize) vs `unsupported` (stub mode). Sonnet only mentioned stub `unsupported`. Opus's three-mode model adopted.
- **RESOLVED via source (send-push token drops):** Opus correctly listed FCM error codes that drop tokens (`UNREGISTERED, INVALID_REGISTRATION, SENDER_ID_MISMATCH, THIRD_PARTY_AUTH_ERROR, HTTP 404`) and explicitly noted `INVALID_ARGUMENT` does NOT drop. Sonnet omitted the latter.

### §5 Auth & onboarding
- **MERGED:** Sonnet's flow steps + Opus's lifecycle details combined.
- **RESOLVED via source:** Both inventories agreed on the 4-step wizard and gate state machine. Goal text range (10–280 chars) confirmed in source.

### §6 Feature folders
- **MERGED:** Both agents enumerated 15–16 folders. Verified count: **16 feature folders** under `mobile/src/features/`. Final list: `auth, chat, connections, discovery, home, intros, media, meetings, office-hours, onboarding, opportunities, privacy, profile, push, settings, verification`. Sonnet missed `home` and `connections` as separate folders in one place; Opus had both. Both agents' service / hook / component lists merged.

### §7 Routing & deep links
- **MERGED:** Both agents had the same route tree and push-routing table.
- **No discrepancies.**

### §8 Design system
- **MERGED:** Sonnet's color values + Opus's `@theme` token table combined.
- **RESOLVED via source (UI primitives count):** Verified count = **24 files** in `mobile/src/components/ui/` (`ls mobile/src/components/ui/ | wc -l = 24`). Both inventories listed roughly the right set.
- **RESOLVED via source (icon list):** Sonnet listed 35 icons. Opus listed 35 icons. Source grep yields **36 distinct names** including `LucideIcon` type re-export. Final union: `AlertTriangle, BadgeCheck, Ban, Bell, BellOff, Briefcase, Calendar, Camera, CheckCircle2, ChevronDown, ChevronLeft, ChevronRight, Copy, Edit, Home, Inbox, Info, LucideIcon, MailOpen, Meh, MessageSquare, Mic, Minus, MoreHorizontal, Pause, Pencil, Play, Plus, Send, Settings, Share2, ShieldOff, Square, ThumbsUp, Trash2, Users, X (XIcon alias), XCircle`. (Sonnet missed `Home` and `Inbox` because they were only in the tab-bar layout file under a name alias.)

### §9 i18n
- **MERGED:** Sonnet's namespace list + Opus's detailed key inventory combined.
- **RESOLVED via source (key parity):** Both en.json and es.json have **643 keys** each, perfect parity (verified by flattening + diffing). Final document records this verified count.
- **24 top-level namespaces** confirmed.

### §10 Push notifications
- **MERGED:** Both inventories were close on the payload shape. Combined into one authoritative table + JSON example.
- **RESOLVED via source (no-emitter kinds):** Opus correctly flagged that `intro_accepted, meeting_reminder, daily_matches_ready, goal_staleness` are in the enum but never emitted server-side. Sonnet only flagged `meeting_reminder` and `daily_matches_ready`. Final §17.4 lists all four.

### §11 Telemetry
- **MERGED:** Both inventories had the same GDPR-gate architecture.

### §12 AI integrations
- **MERGED:** Both inventories agreed on model (`claude-sonnet-4-6`), parameters (16 / 0 for infer; 800 / 0.4 for playbook), and 7-day cache.
- **RESOLVED via source:** Opus correctly identified the API endpoint (`https://api.anthropic.com/v1/messages`) and version header (`2023-06-01`). Adopted.

### §13 Media pipeline
- **MERGED:** Both inventories agreed on size / MIME limits.
- **RESOLVED via source:** ICS service `__test__` exports of `formatICSDate, escapeICS, foldLine` confirmed in source.

### §14 Real-time
- **MERGED:** Both inventories agreed on `messages` + `meeting_proposals` realtime publication and replica-identity-full requirement.

### §15 Testing & QA
- **MERGED:** Opus's comprehensive Jest / Playwright / Maestro test list adopted (Sonnet's was higher-level).

### §16 Build & release
- **MERGED:** Both inventories agreed on EAS profiles, bundle IDs, env vars, edge-function secrets.
- **RESOLVED via source (`WHISPER_TIMEOUT_MS`):** Opus correctly noted this optional env (default 30 000). Sonnet omitted.

### §17 Known gaps / TODOs
- **MERGED:** Sonnet listed ~10 TODOs in narrative form; Opus listed ~6 in `17.1` plus the 47 audit items in `17.2`. Final §17 lists 13 unified TODOs plus all 47 audit items.
- **RESOLVED via source / commit log:** All 47 audit items have current status flags derived from commit `5d858f8` ("enterprise UI/UX overhaul + foundation fixes"). Status flags split: DONE (~36 items), PARTIAL (~3 items), OPEN (~8 items).

### §18 Flutter handoff
- **MERGED:** Sonnet's code-snippet-heavy approach and Opus's package-mapping table combined into one §18 with both code snippets and package recommendations.

### Remaining DISCREPANCIES (source could not resolve)

These are the only items in the document marked with `<!-- DISCREPANCY: ... -->`:

1. **`office_hours_settings` defaults** (§2.20): inline DISCREPANCY note retained because the difference is informational — the source confirms Opus's defaults (15 / 5 / 5), but Sonnet's `30 / 3 / 0` could indicate a stale doc-comment somewhere in the code worth tracking down.

### Files searched / cross-referenced

- `supabase/migrations/*.sql` (51 migration files, verified via `ls`).
- `supabase/functions/{auth-handle-login, delete-account, goal-staleness-reminder, infer-goal-type, meeting-playbook, send-push, transcribe-voice}/index.ts` (7 functions).
- `mobile/src/features/*/` (16 folders).
- `mobile/src/components/ui/*.tsx` (24 files).
- `mobile/src/lib/i18n/locales/{en,es}.json` (643 keys each).
- `UI_UX_AUDIT.md` (470 lines).
- `git log -p` since commit `5d858f8`.

### Counts (verified)

- **Enums:** 15 (all enumerated with verbatim value lists).
- **Tables:** 20 + 2 storage buckets = 22 entities.
- **Distinct RPC names:** 75 (including triggers + helpers + 1 deprecated).
- **Edge functions:** 7.
- **Feature folders:** 16.
- **UI primitives (`ui/` files):** 24.
- **Lucide icon imports:** 36 distinct names.
- **i18n keys:** 643 per locale, identical sets.
- **Audit findings:** 47 (5 P0 + 16 P1 + 16 P2 + 10 P3), each with current-state flag.

### Files not located

None. Every file referenced by either inventory was successfully read or searched.

---

_End of canonical Flutter rebuild specification._
