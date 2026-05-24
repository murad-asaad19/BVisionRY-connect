# Edge Functions

This project ships five Deno edge functions under `supabase/functions/`.
Each documents its env requirements, trigger source, and contract below.
Common env helpers live in `_shared/env.ts` (`requireEnv`, `optionalEnv`,
`verifyWebhookSecret`); CORS helper in `_shared/cors.ts`.

## Summary table

| Function | JWT | Trigger / Invoker | Required env | Optional env |
| --- | --- | --- | --- | --- |
| `auth-handle-login` | off | mobile app (anon) | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` | — |
| `delete-account` | required | mobile app (user JWT) | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` | `DELETE_ACCOUNT_ALLOWED_ORIGINS` (comma-separated CORS allow-list; defaults to `https://app.bvisionry.com,connect-mobile://`) |
| `send-push` | off (shared secret) | Postgres trigger via `dispatch_push` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET` | `FCM_SERVICE_ACCOUNT_JSON` |
| `transcribe-voice` | off (shared secret) | Postgres trigger via `dispatch_transcription` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET` | `WHISPER_API_KEY` or `OPENAI_API_KEY`, `WHISPER_TIMEOUT_MS` |
| `goal-staleness-reminder` | off (shared secret) | `pg_cron` (`goal-staleness-daily`, 09:00 UTC) | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET` | `MAILER_KEY` |

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` are
auto-injected by the Supabase Edge runtime in production. For
`supabase functions serve` (local), provide them via `supabase/.env`
(template: `supabase/.env.example`).

All functions assert their required env vars at module load and refuse
to boot if any are missing. JWT settings are pinned in `supabase/config.toml`
under each function's `[functions.<name>]` block.

## Required Postgres GUCs

The database dispatcher functions invoke edge functions via `pg_net.http_post`.
They source the function host and shared secret from cluster GUCs:

| GUC | Used by | Example value |
| --- | --- | --- |
| `app.functions_base_url` | `dispatch_push`, `dispatch_transcription`, `goal-staleness-daily` cron | `https://<project-ref>.functions.supabase.co` |
| `app.webhook_shared_secret` | `dispatch_push`, `dispatch_transcription`, `goal-staleness-daily` cron (fallback) | matches the `WEBHOOK_SHARED_SECRET` env var on the functions |
| `app.goal_staleness_secret` | `goal-staleness-daily` cron (preferred) — optional | dedicated secret for the goal-staleness endpoint; falls back to `app.webhook_shared_secret` when unset |

Set them at the cluster level:

```sql
alter database postgres set app.functions_base_url = 'https://<project-ref>.functions.supabase.co';
alter database postgres set app.webhook_shared_secret = '<same-as-WEBHOOK_SHARED_SECRET>';
```

Per-session override is possible via `set_config('app.<name>', '<value>', false)`.

## Per-function detail

### `auth-handle-login`

- **Purpose:** Pre-login endpoint that resolves a public `@handle` to the
  associated `auth.users` email server-side, then calls `signInWithPassword`.
  Exists so the handle → email mapping is not exposed to anon clients via an
  RPC (see migration `20260606060000_revoke_handle_lookup.sql`).
- **Trigger:** Mobile sign-in screen (anon — JWT off).
- **Env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`.
- **GUC:** none.
- **Invocation:**
  ```bash
  curl -X POST "$SUPABASE_URL/functions/v1/auth-handle-login" \
    -H "Content-Type: application/json" \
    -d '{"handle":"murad","password":"<password>"}'
  ```
  Always returns `401 {"error":"invalid_credentials"}` on any failure to
  prevent enumeration of account state.

### `delete-account`

- **Purpose:** Two-step, both idempotent:
  1. Call SECURITY DEFINER RPC `public.delete_my_account()` as the user —
     wipes intros, messages, conversations (cascades), meeting proposals,
     `push_log`, `device_tokens`, `conversation_reads`/`mutes`, `blocks`,
     `reports`, notification preferences, `meeting_feedback`,
     `meeting_reviews`, `daily_matches`, and the `profiles` row itself.
  2. Service-role `admin.auth.admin.deleteUser(uid)`. A "user not found"
     error is treated as success.
- **Trigger:** Mobile app (user JWT).
- **Env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`.
- **GUC:** none.
- **Invocation:**
  ```bash
  curl -X POST "$SUPABASE_URL/functions/v1/delete-account" \
    -H "Authorization: Bearer <user-jwt>"
  ```

### `send-push`

- **Purpose:** Sends FCM v1 push notifications to a recipient's registered
  device tokens. Looks up tokens in `public.device_tokens`, ratchets through
  the FCM endpoint, and best-effort updates `push_log` on delivery.
- **Trigger:** Postgres trigger via `public.dispatch_push` (defined in
  `20260521000000_slice8_push.sql` and updated in
  `20260606050000_dispatch_webhook_secret.sql` to send the shared-secret
  header).
- **Env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET`,
  optional `FCM_SERVICE_ACCOUNT_JSON` (full Google service account JSON
  body, single-line or base64; required for actual delivery — without it
  the function logs and no-ops, useful in dev).
- **GUC:** `app.functions_base_url`, `app.webhook_shared_secret`.
- **push_log binding:** requires the `(event_table, event_id, recipient_id)`
  tuple to exist in `public.push_log` with `created_at` within the last 5
  minutes; otherwise returns 403. The `dispatch_push` SQL function inserts
  the row before calling the function, so legitimate flows always satisfy
  this. Prevents arbitrary actors (even with the shared secret leaked) from
  sending unbounded pushes.
- **Invocation (manual debug):**
  ```bash
  curl -X POST "$SUPABASE_URL/functions/v1/send-push" \
    -H "X-Supabase-Webhook-Secret: $WEBHOOK_SHARED_SECRET" \
    -H "Content-Type: application/json" \
    -d '{
      "event_table": "messages",
      "event_id":    "00000000-0000-0000-0000-000000000001",
      "recipient_id":"11111111-1111-1111-1111-111111111111",
      "payload": {
        "kind":  "message_received",
        "title": "Test",
        "body":  "hi",
        "url":   "/(app)/chat/abc"
      }
    }'
  ```
  `recipient_id` and `event_id` are validated as UUIDs (400 on invalid).
  The endpoint additionally requires a matching tuple in `push_log` with
  `delivered = false` and `created_at` within the last 5 minutes — manual
  debug calls therefore need a real row inserted by `dispatch_push` first,
  or they will 403.

### `transcribe-voice`

- **Purpose:** Downloads a voice message audio file from Supabase Storage,
  forwards it to Whisper, and writes the transcript back to
  `messages.transcript`.
- **Trigger:** Postgres trigger via `public.dispatch_transcription` (defined
  in `20260603000000_phase3_features.sql` and updated in
  `20260606050000_dispatch_webhook_secret.sql`).
- **Env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET`,
  optional `WHISPER_API_KEY` (preferred) or `OPENAI_API_KEY` (fallback).
- **GUC:** `app.functions_base_url`, `app.webhook_shared_secret`.
- **Behavior:**
  - Validates the message exists and `kind = 'voice'` before doing anything.
  - All `update messages` statements include `and kind = 'voice'`.
  - **Idempotent:** if `transcript_status` is already `'ready'` or
    `'unsupported'`, returns `{ok:true, skipped:true, reason:<status>}`
    without re-calling Whisper. `'failed'` is intentionally retried.
  - Aborts the storage download after 30 s and the Whisper request after
    `WHISPER_TIMEOUT_MS` (default 30 000 ms). Rejects audio over 25 MiB
    before calling Whisper.
  - Derives the multipart filename extension from `media_path` (allow-list:
    m4a, mp3, mp4, mpeg, mpga, wav, webm, aac, ogg, opus, flac; fallback m4a)
    so Whisper sniffs the correct container/codec on Android recordings.
  - On failure: sets `messages.transcript_status = 'failed'` and leaves
    `messages.transcript` NULL — never writes an error string into transcript.
- **`transcript_status` values used:** `'pending'`, `'ready'`, `'failed'`,
  `'unsupported'`. If the column is converted to an enum in a future migration,
  these values must be preserved.
- **Invocation (manual debug):**
  ```bash
  curl -X POST "$SUPABASE_URL/functions/v1/transcribe-voice" \
    -H "X-Supabase-Webhook-Secret: $WEBHOOK_SHARED_SECRET" \
    -H "Content-Type: application/json" \
    -d '{"message_id":"<uuid>"}'
  ```

### `goal-staleness-reminder`

- **Purpose:** Daily sweep — finds profiles whose `goal_updated_at` is older
  than `STALE_DAYS = 56` days and sends a nudge. Returns
  `{ok:true, emailed:<n>}`.
- **Trigger:** `pg_cron` job `goal-staleness-daily` registered in
  `20260606140000_scheduled_jobs.sql`; runs at 09:00 UTC and POSTs the
  function URL with `X-Supabase-Webhook-Secret`. The function rejects requests
  whose header does not match `WEBHOOK_SHARED_SECRET` with `401`.
- **Env:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SHARED_SECRET`,
  optional `MAILER_KEY` (without it the function logs intended recipients and
  returns 0).
- **GUC:** `app.functions_base_url` (URL); `app.goal_staleness_secret` or
  `app.webhook_shared_secret` (header value).
- **Fallback when `pg_cron` is unavailable:** schedule a GitHub Actions
  workflow with `schedule: cron:` or use Supabase Scheduled Functions; both
  should `curl -X POST` the endpoint with the same shared-secret header.
- **Invocation (manual debug):**
  ```bash
  curl -X POST "$SUPABASE_URL/functions/v1/goal-staleness-reminder" \
    -H "X-Supabase-Webhook-Secret: $WEBHOOK_SHARED_SECRET"
  ```

## Shared webhook secret

`send-push` and `transcribe-voice` are invoked from the database via `pg_net`,
which cannot carry a user JWT. JWT verification is therefore disabled in
`supabase/config.toml`, and each function rejects requests that do not carry
the `X-Supabase-Webhook-Secret` header matching `WEBHOOK_SHARED_SECRET`.

The Postgres dispatchers must pass this header — see
`20260606050000_dispatch_webhook_secret.sql` which wires
`current_setting('app.webhook_shared_secret', true)` into the
`net.http_post(...)` call.

### Rotation procedure

The GUC and env var MUST stay in sync. Any drift produces 401s on every
dispatch. Rotate as a single atomic operation:

1. Generate a new secret: `openssl rand -hex 32`.
2. Set the env var on the edge functions first (so they accept the new value
   on next cold start):
   ```bash
   supabase secrets set WEBHOOK_SHARED_SECRET='<new-secret>'
   ```
3. Update the database GUC and force any pooled sessions to pick it up:
   ```sql
   alter database postgres set app.webhook_shared_secret = '<new-secret>';
   ```
   Then run `select pg_reload_conf();` and, ideally, restart the connection
   pool so existing sessions re-read the GUC.
4. Verify with a manual dispatcher fire (insert into a watched table that
   trips `dispatch_push`, confirm 200).

Until both sides match, dispatches will 401. If you cannot rotate atomically,
update the env var first (functions accept new secret) and then the GUC
(dispatchers send new secret); the dispatcher continues to send the old
value, which is rejected — so prefer truly atomic ops on the same maintenance
window.

## Deployment

Deploy a single function:

```bash
supabase functions deploy <function-name>
```

Bulk-set secrets from `supabase/.env` (template: `supabase/.env.example`):

```bash
supabase secrets set --env-file supabase/.env
```

One-off secret:

```bash
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat path/to/firebase-admin.json | jq -c .)"
```

List currently-set secrets:

```bash
supabase secrets list
```

The `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` triplet
is provided by the platform — do NOT set them via `supabase secrets set` in
production (you will collide with the platform-injected values).

### Mobile / EAS secrets

Front-end `EXPO_PUBLIC_*` values (consumed by the mobile app build, NOT by
edge functions) are managed separately via EAS:

```bash
eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_URL --value 'https://<ref>.supabase.co'
eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_ANON_KEY --value 'sb_publishable_...'
eas secret:create --scope project --name EXPO_PUBLIC_SENTRY_DSN --value 'https://...@sentry.io/<id>'
eas secret:create --scope project --name EXPO_PUBLIC_EAS_PROJECT_ID --value '<uuid>'
eas secret:create --scope project --name EXPO_PUBLIC_APP_LINKS_HOST --value 'connect.example.com'
# Build-time-only (NOT bundled in JS):
eas secret:create --scope project --name SENTRY_AUTH_TOKEN --value '...'
eas secret:create --scope project --name SENTRY_ORG --value '<org-slug>'
eas secret:create --scope project --name SENTRY_PROJECT --value '<project-slug>'
```

Per-profile overrides for these vars live in `mobile/eas.json` under
`build.<profile>.env`; the literal sentinel `SET_IN_EAS_SECRETS` means
"this slot must be filled by an EAS secret of the same name before building".
Full template in `mobile/.env.example`.

## Local dev

```bash
# 1. Start the local Supabase stack (postgres, auth, storage, functions runtime).
supabase start

# 2. Copy the env template and fill in local values. SUPABASE_URL and the
#    anon / service-role keys come from `supabase status`.
cp supabase/.env.example supabase/.env

# 3. Set the Postgres GUCs the dispatcher functions read. Easiest via SQL
#    editor in Supabase Studio (http://127.0.0.1:54323), or psql:
psql "$DATABASE_URL" <<SQL
  alter database postgres set app.functions_base_url
    = 'http://host.docker.internal:54321/functions/v1';
  alter database postgres set app.webhook_shared_secret
    = '<same value as WEBHOOK_SHARED_SECRET in supabase/.env>';
SQL

# 4. Serve the functions locally (picks up supabase/.env).
supabase functions serve --env-file supabase/.env

# 5. Invoke a function:
supabase functions invoke auth-handle-login --body '{"handle":"murad","password":"…"}'

# Or with curl (use the local service key when calling JWT-protected functions):
curl -X POST http://127.0.0.1:54321/functions/v1/delete-account \
  -H "Authorization: Bearer $(supabase status | awk '/service_role/ {print $NF}')"
```

For webhook-style functions in local dev, you can either trigger the database
flow that fires the dispatcher (recommended — catches GUC misconfigurations),
or call the function directly with the shared-secret header set to whatever
you put in `supabase/.env`.

## Scheduled jobs (`pg_cron`)

Registered in `supabase/migrations/20260606140000_scheduled_jobs.sql`. The
extension is allowlisted via `supabase/config.toml` (`[db.extensions]`).

| Job name | Schedule (UTC) | Effect |
| --- | --- | --- |
| `expire-overdue-intros` | `0 * * * *` (hourly) | Calls `public.expire_overdue_intros()` to flip stale `delivered` intros past `expires_at` to `expired`. |
| `goal-staleness-daily` | `0 9 * * *` (09:00) | POSTs `goal-staleness-reminder` with `X-Supabase-Webhook-Secret`. |
| `fcm-token-cleanup` | `0 3 * * *` (03:00) | Deletes `device_tokens` rows that have been `revoked_at` for more than 7 days, or whose `last_seen_at` is older than 90 days. |

All three are registered idempotently — re-running the migration is a no-op
if a job of the same name already exists. To re-create one, unschedule it
first:

```sql
select cron.unschedule('goal-staleness-daily');
```

If `pg_cron` cannot be enabled in your deployment, comment out the
`create extension ...` line in the migration and instead schedule the
equivalents via Supabase Scheduled Functions, GitHub Actions, or an
external cron host that has psql + a Supabase URL.

## CORS

`_shared/cors.ts` exposes two flavours:

- `handlePreflight(req)` + `jsonResponse(body, status)` — permissive
  `Access-Control-Allow-Origin: *`. Used by webhook-style functions
  (`send-push`, `transcribe-voice`, `goal-staleness-reminder`) that are
  never invoked from a browser and reject anyone without the shared secret.
- `handlePreflightRestricted(req, allowed)` +
  `jsonResponseRestricted(req, allowed, body, status)` — echoes back
  `Origin` only when on the allow-list, sets `Vary: Origin` and
  `Access-Control-Allow-Credentials: true`. Used by `delete-account` since
  it carries a user JWT (a credentialed endpoint MUST NOT respond with
  `Allow-Origin: *`).

Default allow-list for `delete-account`:
`https://app.bvisionry.com`, `connect-mobile://`. Override per-deployment via
the `DELETE_ACCOUNT_ALLOWED_ORIGINS` env (comma-separated, exact match).

## Tests

### Edge function tests (Deno)

Each function ships a sibling `index.test.ts` that imports the exported
`handler(req)` and exercises it in isolation — no Supabase containers
needed and no real network calls. The minimal refactor in each `index.ts`
is just `export async function handler(req) { ... }` followed by
`serve(handler)`, so the production boot path is unchanged.

```bash
# Repo-root npm script (recommended):
npm run functions:test

# Or directly:
deno test --allow-net --allow-env --allow-read supabase/functions/
```

Helpers live in `_shared/test-utils.ts`:

- `setDefaultEnv()` — stubs `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`,
  `SUPABASE_ANON_KEY`, `WEBHOOK_SHARED_SECRET` (required by `requireEnv()`
  at module load).
- `mockFetch(handler)` — replaces `globalThis.fetch` with a router for the
  test's duration; returns `restore()` for the `finally` block.
- `makeRequest(url, { method, body, headers })` — builds a `Request` for the
  handler input.

Each test file calls `setDefaultEnv()` before `await import("./index.ts")`,
since the handlers' top-level `requireEnv()` would otherwise throw at import.

### Database tests (pgTAP)

The pgTAP suite lives at `supabase/tests/pgtap/*.sql` and is wired up via the
`[db.tests] paths` block in `supabase/config.toml`. Each .sql file is a
self-contained `BEGIN; SELECT plan(N); ... SELECT * FROM finish(); ROLLBACK;`
transaction — fixture helpers (e.g. `tests.make_user`) are declared inside
each file and roll back with the test data so there is no cross-file leak.

```bash
# Repo-root npm script (recommended):
npm run supabase:test

# Or directly (auto-boots the local stack if needed):
supabase test db --local
```

The runner uses `pg_prove`, which ships with the Supabase CLI; the
`pgtap` extension must be available on the database (Supabase enables it by
default in local stacks and managed projects).
