// Phase 15 — Supabase seed for integration tests.
//
// Inserts the three [TestUsers] into the local Supabase stack via the
// auth admin REST API + `profiles` table. Requires
// `SUPABASE_SERVICE_ROLE_KEY` and `SUPABASE_URL` as dart-defines (only
// used in test runs — never embedded in app builds).

import 'dart:convert';
import 'dart:io';

import 'fixtures.dart';

const _serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

bool get isSeedEnabled => _serviceRoleKey.isNotEmpty && _supabaseUrl.isNotEmpty;

Future<void> seedAll() async {
  if (!isSeedEnabled) {
    // Tests that require a real Supabase will assert isSeedEnabled and
    // skip themselves; this guard avoids accidental no-op runs.
    return;
  }

  for (final u in [TestUsers.ana, TestUsers.bruno, TestUsers.carla]) {
    await _createAuthUser(u);
    if (u.onboarded) {
      await _upsertProfile(u);
    }
  }
}

Future<void> _createAuthUser(TestUser u) async {
  final client = HttpClient();
  try {
    final req =
        await client.postUrl(Uri.parse('$_supabaseUrl/auth/v1/admin/users'));
    req.headers.set('apikey', _serviceRoleKey);
    req.headers.set('Authorization', 'Bearer $_serviceRoleKey');
    req.headers.set('Content-Type', 'application/json');
    req.add(
      utf8.encode(
        jsonEncode({
          'id': u.id,
          'email': u.email,
          'password': u.password,
          'email_confirm': true,
        }),
      ),
    );
    final res = await req.close();
    await res.drain<void>();
  } finally {
    client.close();
  }
}

Future<void> _upsertProfile(TestUser u) async {
  final client = HttpClient();
  try {
    final req = await client
        .postUrl(Uri.parse('$_supabaseUrl/rest/v1/profiles?on_conflict=id'));
    req.headers.set('apikey', _serviceRoleKey);
    req.headers.set('Authorization', 'Bearer $_serviceRoleKey');
    req.headers.set('Content-Type', 'application/json');
    req.headers.set('Prefer', 'resolution=merge-duplicates,return=minimal');
    req.add(
      utf8.encode(
        jsonEncode({
          'id': u.id,
          'handle': u.handle,
          'display_name': u.displayName,
          'onboarded': u.onboarded,
          'goal_text': 'Connect with senior engineers and designers.',
          'goal_type': 'hire',
          'roles': ['founder'],
        }),
      ),
    );
    final res = await req.close();
    await res.drain<void>();
  } finally {
    client.close();
  }
}
