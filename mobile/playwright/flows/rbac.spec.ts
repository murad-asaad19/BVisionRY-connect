/* eslint-disable @typescript-eslint/no-explicit-any */
import { test, expect } from '@playwright/test';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { execSync } from 'node:child_process';
import path from 'node:path';

/**
 * RBAC / RLS negative test suite.
 *
 * Pure supabase-js — no browser pages. Each test is a negative assertion:
 * user A reaching for user B's data and being denied (either via RLS hiding
 * rows, an RPC raising EXCEPTION, or storage policy denying the request).
 *
 * Note on supabase-js denial semantics:
 *   - SELECT denied by RLS  -> { data: [], error: null }
 *   - UPDATE denied by RLS  -> { data: null, error: null }, no rows affected
 *                             (verify by re-reading with the owner's client)
 *   - DELETE denied by RLS  -> { data: null, error: null }, no rows deleted
 *                             (verify by re-reading with the owner's client)
 *   - INSERT denied by RLS  -> { data: null, error: <RLS violation> }
 *   - RPC EXCEPTION         -> { data: null, error: <SQL error message> }
 *   - PostgREST grant denied -> error.message: "permission denied for function ..."
 *   - Storage denied         -> { data: null, error: <New row violates / not found> }
 */

const REPO_ROOT = path.resolve(__dirname, '..', '..', '..');
const TEST_PASSWORD = 'TestPass123!';

function readSupabaseEnv(): { url: string; serviceRoleKey: string; anonKey: string } {
  // `supabase status -o json` emits a single JSON object with SERVICE_ROLE_KEY
  // (real JWT, what supabase-js needs) plus API_URL and ANON_KEY.
  const raw = execSync('npx supabase status -o json', {
    cwd: REPO_ROOT,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  // The CLI sometimes prepends a "Stopped services: [...]" line before JSON.
  const jsonStart = raw.indexOf('{');
  const parsed = JSON.parse(raw.slice(jsonStart)) as Record<string, string>;
  const url = parsed.API_URL;
  const serviceRoleKey = parsed.SERVICE_ROLE_KEY;
  const anonKey = parsed.ANON_KEY;
  if (!url || !serviceRoleKey || !anonKey) {
    throw new Error('supabase status returned no API_URL / SERVICE_ROLE_KEY / ANON_KEY');
  }
  return { url, serviceRoleKey, anonKey };
}

function makeClient(url: string, key: string): SupabaseClient {
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function signInClient(url: string, anonKey: string, email: string): Promise<SupabaseClient> {
  const client = makeClient(url, anonKey);
  const { error } = await client.auth.signInWithPassword({ email, password: TEST_PASSWORD });
  if (error) throw new Error(`signIn(${email}): ${error.message}`);
  return client;
}

// ---------------------------------------------------------------------------
// Shared state across the describe block.
// ---------------------------------------------------------------------------
type Ctx = {
  url: string;
  anonKey: string;
  service: SupabaseClient;
  anon: SupabaseClient;
  alice: SupabaseClient;
  bob: SupabaseClient;
  charlie: SupabaseClient;
  aliceId: string;
  bobId: string;
  charlieId: string;
  aliceConvId: string;
  aliceIntroId: string;
  aliceMessageId: string;
};

const state: Partial<Ctx> = {};
const ctx = state as Ctx;

test.describe.configure({ mode: 'serial' });

test.describe('RBAC — RLS negative tests', () => {
  test.beforeAll(async () => {
    const { url, serviceRoleKey, anonKey } = readSupabaseEnv();
    ctx.url = url;
    ctx.anonKey = anonKey;
    ctx.service = makeClient(url, serviceRoleKey);
    ctx.anon = makeClient(url, anonKey);

    // 1. Purge any leftover RBAC test users from a previous run.
    //    Use a service-role SQL call rather than supabase db query so we
    //    don't depend on the CLI staying connected to docker for every test.
    const { error: purgeErr } = await ctx.service.rpc('exec_sql' as any, {});
    // exec_sql doesn't exist by design — instead delete via admin API after
    // listing users. Cleaner than shelling out to psql.
    void purgeErr; // ignore

    // List then delete any prior rbac-* users via admin API.
    const { data: priorUsers } = await ctx.service.auth.admin.listUsers({
      page: 1,
      perPage: 200,
    });
    if (priorUsers?.users?.length) {
      for (const u of priorUsers.users) {
        if (u.email && u.email.startsWith('rbac-') && u.email.endsWith('@example.com')) {
          await ctx.service.auth.admin.deleteUser(u.id);
        }
      }
    }

    // 2. Create three users.
    const ts = Date.now();
    const mk = async (slug: string) => {
      const email = `rbac-${slug}-${ts}@example.com`;
      const { data, error } = await ctx.service.auth.admin.createUser({
        email,
        password: TEST_PASSWORD,
        email_confirm: true,
      });
      if (error || !data?.user) throw new Error(`createUser(${email}): ${error?.message}`);
      return { id: data.user.id, email };
    };
    const aliceUser = await mk('alice');
    const bobUser = await mk('bob');
    const charlieUser = await mk('charlie');
    ctx.aliceId = aliceUser.id;
    ctx.bobId = bobUser.id;
    ctx.charlieId = charlieUser.id;

    // 3. Onboard profile rows for each (service-role bypasses RLS).
    //    handle_new_auth_user trigger has already inserted a row with just
    //    (id, email). Use UPDATE rather than UPSERT so we don't re-insert and
    //    trip the not-null email constraint (PostgREST upsert sends NULL for
    //    omitted columns on INSERT).
    const updates: Array<{ id: string; handle: string; name: string }> = [
      { id: ctx.aliceId, handle: `rbacalice${ts}`, name: 'Alice RBAC' },
      { id: ctx.bobId, handle: `rbacbob${ts}`, name: 'Bob RBAC' },
      { id: ctx.charlieId, handle: `rbaccharlie${ts}`, name: 'Charlie RBAC' },
    ];
    for (const u of updates) {
      const { error: upErr } = await ctx.service
        .from('profiles')
        .update({
          handle: u.handle,
          name: u.name,
          roles: ['builder'],
          primary_role: 'builder',
          goal_type: 'peer_connect',
          goal_text:
            'Connecting with other AI builders for collaboration on early stage products.',
          city: 'Berlin',
          country: 'Germany',
          onboarded: true,
        })
        .eq('id', u.id);
      if (upErr) throw new Error(`profile update (${u.handle}): ${upErr.message}`);
    }

    // 4. Sign in each user.
    ctx.alice = await signInClient(url, anonKey, aliceUser.email);
    ctx.bob = await signInClient(url, anonKey, bobUser.email);
    ctx.charlie = await signInClient(url, anonKey, charlieUser.email);

    // 5. Create one intro Alice -> Bob via service-role.
    const note =
      'Hi Bob, this is the RBAC test fixture. We use this intro to verify cross-user authorization on intros. Cheers.';
    expect(note.length).toBeGreaterThanOrEqual(80);
    const { data: introRow, error: introErr } = await ctx.service
      .from('intros')
      .insert({
        sender_id: ctx.aliceId,
        recipient_id: ctx.bobId,
        note,
      })
      .select()
      .single();
    if (introErr || !introRow) throw new Error(`intro insert: ${introErr?.message}`);
    ctx.aliceIntroId = introRow.id;

    // 6. Create a conversation between Alice + Bob in canonical order.
    const a = ctx.aliceId < ctx.bobId ? ctx.aliceId : ctx.bobId;
    const b = ctx.aliceId < ctx.bobId ? ctx.bobId : ctx.aliceId;
    const { data: convRow, error: convErr } = await ctx.service
      .from('conversations')
      .insert({ participant_a_id: a, participant_b_id: b })
      .select()
      .single();
    if (convErr || !convRow) throw new Error(`conversation insert: ${convErr?.message}`);
    ctx.aliceConvId = convRow.id;

    // 7. Insert one text message from Alice.
    const { data: msgRow, error: msgErr } = await ctx.service
      .from('messages')
      .insert({
        conversation_id: ctx.aliceConvId,
        sender_id: ctx.aliceId,
        kind: 'text',
        body: 'Hello from Alice (RBAC fixture)',
      })
      .select()
      .single();
    if (msgErr || !msgRow) throw new Error(`message insert: ${msgErr?.message}`);
    ctx.aliceMessageId = msgRow.id;
  });

  test.afterAll(async () => {
    if (!ctx.service) return;
    for (const id of [ctx.aliceId, ctx.bobId, ctx.charlieId]) {
      if (id) {
        try {
          await ctx.service.auth.admin.deleteUser(id);
        } catch {
          // best-effort
        }
      }
    }
  });

  // -------------------------------------------------------------------------
  // Profile boundaries
  // -------------------------------------------------------------------------
  //
  // Migration 20260601000000_fix_anon_profile_leak.sql tightened
  // profiles_select_discoverable to require auth.uid() is not null, so
  // anonymous clients can no longer enumerate profiles at all.
  test('T1: anon cannot select any profile (including onboarded ones)', async () => {
    const { data, error } = await ctx.anon
      .from('profiles')
      .select('id, name')
      .eq('id', ctx.aliceId);
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test('T2: Bob cannot UPDATE Alice profile (re-read shows unchanged)', async () => {
    await ctx.bob.from('profiles').update({ name: 'Hacked by Bob' }).eq('id', ctx.aliceId);
    // Re-read with Alice's own client.
    const { data, error } = await ctx.alice.from('profiles').select('name').eq('id', ctx.aliceId).single();
    expect(error).toBeNull();
    expect(data?.name).toBe('Alice RBAC');
  });

  test('T3: Bob cannot DELETE Alice profile (re-read shows still present)', async () => {
    await ctx.bob.from('profiles').delete().eq('id', ctx.aliceId);
    const { data, error } = await ctx.alice.from('profiles').select('id').eq('id', ctx.aliceId).single();
    expect(error).toBeNull();
    expect(data?.id).toBe(ctx.aliceId);
  });

  // -------------------------------------------------------------------------
  // Intro boundaries
  // -------------------------------------------------------------------------
  test('T4: Charlie cannot SELECT the Alice->Bob intro', async () => {
    const { data, error } = await ctx.charlie.from('intros').select('id').eq('id', ctx.aliceIntroId);
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test('T5: Charlie cannot accept_intro on Alice->Bob intro', async () => {
    const { error } = await ctx.charlie.rpc('accept_intro', { p_intro_id: ctx.aliceIntroId });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/only the recipient/i);
  });

  test('T6: Charlie cannot decline_intro on Alice->Bob intro', async () => {
    const { error } = await ctx.charlie.rpc('decline_intro', { p_intro_id: ctx.aliceIntroId });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/only the recipient/i);
  });

  test('T7: Bob cannot send_intro to himself', async () => {
    const note =
      'Self intro attempt for the RBAC negative path tests in this comprehensive suite of authorization checks.';
    expect(note.length).toBeGreaterThanOrEqual(80);
    const { error } = await ctx.bob.rpc('send_intro', {
      p_recipient_id: ctx.bobId,
      p_note: note,
    });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/cannot intro to self/i);
  });

  test('T8: anon cannot call send_intro', async () => {
    const note =
      'Anonymous intro attempt for the RBAC negative path tests in this comprehensive suite of authorization checks.';
    const { error } = await ctx.anon.rpc('send_intro', {
      p_recipient_id: ctx.aliceId,
      p_note: note,
    });
    expect(error).toBeTruthy();
    // Anon hits PostgREST's grant check first ("permission denied"), not the
    // RPC body's `unauthenticated` raise. Accept either.
    expect(error?.message ?? '').toMatch(/permission denied|unauthenticated/i);
  });

  // -------------------------------------------------------------------------
  // Conversation + message boundaries
  // -------------------------------------------------------------------------
  test('T9: Charlie cannot SELECT the Alice<->Bob conversation', async () => {
    const { data, error } = await ctx.charlie
      .from('conversations')
      .select('id')
      .eq('id', ctx.aliceConvId);
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test('T10: Charlie cannot SELECT messages in the Alice<->Bob conversation', async () => {
    const { data, error } = await ctx.charlie
      .from('messages')
      .select('id')
      .eq('conversation_id', ctx.aliceConvId);
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test('T11: Charlie cannot INSERT a message into the Alice<->Bob conversation', async () => {
    const { error } = await ctx.charlie.from('messages').insert({
      conversation_id: ctx.aliceConvId,
      sender_id: ctx.charlieId,
      kind: 'text',
      body: 'spam from Charlie',
    });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/row-level security/i);
  });

  test('T12: Bob cannot spoof sender_id=Alice when inserting a message (SECURITY)', async () => {
    const { error } = await ctx.bob.from('messages').insert({
      conversation_id: ctx.aliceConvId,
      sender_id: ctx.aliceId, // spoofed
      kind: 'text',
      body: 'spoofed message claiming to be from Alice',
    });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/row-level security/i);
  });

  test('T13: Bob cannot edit_message a message authored by Alice', async () => {
    const { error } = await ctx.bob.rpc('edit_message', {
      p_id: ctx.aliceMessageId,
      p_body: 'tampered by Bob',
    });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/sender/i);
  });

  test('T14: Bob cannot delete_message a message authored by Alice', async () => {
    const { error } = await ctx.bob.rpc('delete_message', { p_id: ctx.aliceMessageId });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/sender/i);
  });

  test('T15: anon cannot INSERT a message anywhere', async () => {
    const { error } = await ctx.anon.from('messages').insert({
      conversation_id: ctx.aliceConvId,
      sender_id: ctx.aliceId,
      kind: 'text',
      body: 'anonymous spam',
    });
    expect(error).toBeTruthy();
  });

  // -------------------------------------------------------------------------
  // Push + tokens
  // -------------------------------------------------------------------------
  test("T16: Charlie cannot SELECT another user's device_tokens", async () => {
    // Seed: insert a device token for Alice via service-role.
    const dummyToken = `rbac-token-${Date.now()}-aaaaaaaaaaaaaaaa`;
    const { error: seedErr } = await ctx.service.from('device_tokens').insert({
      user_id: ctx.aliceId,
      token: dummyToken,
      platform: 'web',
    });
    expect(seedErr).toBeNull();

    const { data, error } = await ctx.charlie.from('device_tokens').select('id, user_id, token');
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test("T17: Charlie cannot SELECT another user's push_log rows", async () => {
    // Seed: insert a push_log row destined for Alice.
    const { error: seedErr } = await ctx.service.from('push_log').insert({
      event_table: 'rbac_test',
      event_id: '00000000-0000-0000-0000-000000000001',
      recipient_id: ctx.aliceId,
      payload: { kind: 'rbac_seed' },
    });
    expect(seedErr).toBeNull();

    const { data, error } = await ctx.charlie.from('push_log').select('id, recipient_id');
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  // -------------------------------------------------------------------------
  // Blocks + reports
  // -------------------------------------------------------------------------
  test('T18: Bob calling unblock_user(Charlie) does NOT remove a block Alice owns (SECURITY)', async () => {
    // Alice blocks Charlie.
    const { error: bErr } = await ctx.alice.rpc('block_user', { p_target: ctx.charlieId });
    expect(bErr).toBeNull();

    // Bob tries to unblock Charlie on Alice's behalf.
    const { error: ubErr } = await ctx.bob.rpc('unblock_user', { p_target: ctx.charlieId });
    expect(ubErr).toBeNull(); // returns void either way

    // Alice's blocklist still shows Charlie.
    const { data, error } = await ctx.alice.rpc('list_blocked_users');
    expect(error).toBeNull();
    const list = (data ?? []) as Array<{ blocked_id: string }>;
    expect(list.some((r) => r.blocked_id === ctx.charlieId)).toBe(true);
  });

  test("T19: Charlie cannot SELECT Alice's blocks rows", async () => {
    const { data, error } = await ctx.charlie.from('blocks').select('blocker_id, blocked_id');
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test('T20: anon cannot SELECT any reports (no select policy)', async () => {
    // Seed a report so the table is non-empty.
    await ctx.service.from('reports').insert({
      reporter_id: ctx.aliceId,
      target_type: 'profile',
      target_id: ctx.bobId,
      reason: 'spam',
      note: 'rbac seed',
    });
    const { data, error } = await ctx.anon.from('reports').select('id');
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test('T21: Bob cannot SELECT any reports (no select policy)', async () => {
    const { data, error } = await ctx.bob.from('reports').select('id');
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  // -------------------------------------------------------------------------
  // Conversation reads / mutes (slice 22)
  // -------------------------------------------------------------------------
  test("T22: Charlie cannot SELECT another user's conversation_reads", async () => {
    // Seed via Alice marking the conversation read.
    await ctx.alice.rpc('mark_conversation_read', { p_conversation_id: ctx.aliceConvId });

    const { data, error } = await ctx.charlie
      .from('conversation_reads')
      .select('user_id, conversation_id');
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test("T23: Charlie cannot SELECT another user's conversation_mutes", async () => {
    // Seed via Alice muting the conversation.
    await ctx.alice.rpc('mute_conversation', { p_conversation_id: ctx.aliceConvId });

    const { data, error } = await ctx.charlie
      .from('conversation_mutes')
      .select('user_id, conversation_id');
    expect(error).toBeNull();
    expect(data).toEqual([]);
  });

  test("T24: Bob cannot INSERT a conversation_reads row for Alice (user_id spoof)", async () => {
    const { error } = await ctx.bob.from('conversation_reads').insert({
      user_id: ctx.aliceId,
      conversation_id: ctx.aliceConvId,
    });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(/row-level security/i);
  });

  // -------------------------------------------------------------------------
  // RPC anon denials
  // -------------------------------------------------------------------------
  // Anon hits PostgREST's grant check ("permission denied for function ...")
  // before the RPC body runs, so accept either that or the "unauthenticated"
  // raise from the function body (defense in depth).
  const anonRpcDenied = /permission denied|unauthenticated/i;

  test('T25: anon cannot call list_blocked_users', async () => {
    const { error } = await ctx.anon.rpc('list_blocked_users');
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(anonRpcDenied);
  });

  test('T26: anon cannot call list_connections', async () => {
    const { error } = await ctx.anon.rpc('list_connections');
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(anonRpcDenied);
  });

  test('T27: anon cannot call mark_conversation_read', async () => {
    const { error } = await ctx.anon.rpc('mark_conversation_read', {
      p_conversation_id: ctx.aliceConvId,
    });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(anonRpcDenied);
  });

  test('T28: anon cannot call export_my_data', async () => {
    const { error } = await ctx.anon.rpc('export_my_data');
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(anonRpcDenied);
  });

  test('T29: anon cannot call set_github_verification', async () => {
    const { error } = await ctx.anon.rpc('set_github_verification', {
      p_github_username: 'octo',
      p_github_id: 1,
    });
    expect(error).toBeTruthy();
    expect(error?.message ?? '').toMatch(anonRpcDenied);
  });

  // -------------------------------------------------------------------------
  // Storage
  // -------------------------------------------------------------------------
  test('T30: Charlie cannot download chat-media uploaded by Alice', async () => {
    const objectPath = `${ctx.aliceConvId}/rbac-test/secret-${Date.now()}.png`;
    // Minimal 1x1 PNG (8-byte signature + IHDR + IDAT + IEND).
    const png = new Uint8Array([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
      0x89, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
      0x42, 0x60, 0x82,
    ]);
    const body = new Blob([png], { type: 'image/png' });

    // Alice uploads (she is a participant -> insert policy allows).
    const up = await ctx.alice.storage.from('chat-media').upload(objectPath, body, {
      contentType: 'image/png',
      upsert: false,
    });
    if (up.error) {
      throw new Error(`Alice upload (T30): ${up.error.message}`);
    }

    // Charlie tries to download the same path.
    const dl = await ctx.charlie.storage.from('chat-media').download(objectPath);
    expect(dl.error).toBeTruthy();
    expect(dl.data).toBeNull();
  });

  test("T31: Bob cannot upsert into Alice's avatar folder (SECURITY)", async () => {
    const aliceObjectPath = `${ctx.aliceId}/avatar-${Date.now()}.png`;
    // Pixel-encoded so the upload identifies us correctly (different pixel
    // per upload to detect overwrites).
    const alicePng = new Uint8Array([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
      0x89, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
      0x42, 0x60, 0x82,
    ]);
    const aliceBody = new Blob([alicePng], { type: 'image/png' });
    const aliceUp = await ctx.alice.storage.from('avatars').upload(aliceObjectPath, aliceBody, {
      contentType: 'image/png',
      upsert: false,
    });
    if (aliceUp.error) {
      throw new Error(`Alice avatar upload (T31): ${aliceUp.error.message}`);
    }

    // Bob tries to overwrite the exact same path with upsert. Use a different
    // payload so a successful overwrite would change the bytes Alice reads
    // back. The bucket only allows image/* mimes, so use image/png.
    const bobPng = new Uint8Array(alicePng);
    const perturbIdx = bobPng.length - 5;
    const current = bobPng[perturbIdx] ?? 0;
    bobPng[perturbIdx] = current ^ 0xff; // perturb one byte after IDAT chunk
    const bobBody = new Blob([bobPng], { type: 'image/png' });
    const bobUp = await ctx.bob.storage.from('avatars').upload(aliceObjectPath, bobBody, {
      contentType: 'image/png',
      upsert: true,
    });
    expect(bobUp.error).toBeTruthy();

    // Confirm Alice's bytes are unchanged.
    const dl = await ctx.alice.storage.from('avatars').download(aliceObjectPath);
    expect(dl.error).toBeNull();
    const bytes = new Uint8Array(await dl.data!.arrayBuffer());
    expect(Array.from(bytes)).toEqual(Array.from(alicePng));
  });

  test('T32: anon cannot download any chat-media object', async () => {
    // Use any plausible path; the policy denies regardless because the
    // exists(...) participant subquery returns nothing for auth.uid()=null.
    const probePath = `${ctx.aliceConvId}/anon-probe/nope.txt`;
    const dl = await ctx.anon.storage.from('chat-media').download(probePath);
    expect(dl.error).toBeTruthy();
    expect(dl.data).toBeNull();
  });
});
