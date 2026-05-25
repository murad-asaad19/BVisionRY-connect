import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

/// Test-seam abstraction over the Postgrest `profiles.select(...).eq(id, ...)`
/// chain. The concrete [SupabaseProfileQueryRunner] adapts the real client;
/// tests inject a hand-rolled fake.
abstract class ProfileQueryRunner {
  /// Returns the matching profile row, or `null` when no row exists.
  Future<Map<String, dynamic>?> selectById(String id);
}

/// Production [ProfileQueryRunner] backed by `supabase_flutter`.
class SupabaseProfileQueryRunner implements ProfileQueryRunner {
  SupabaseProfileQueryRunner(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> selectById(String id) async {
    final res = await _client
        .from('profiles')
        .select('id, onboarded, suspended_at, handle, name, private_mode')
        .eq('id', id)
        .maybeSingle();
    return res;
  }
}

/// Wraps profile reads. The single `fetchOwn` entry point returns `null`
/// when the row is missing (callers treat that as "not yet onboarded").
class ProfileRepository {
  ProfileRepository(this._runner);
  final ProfileQueryRunner _runner;

  /// Fetch the signed-in user's profile. Returns `null` when no row exists
  /// yet (e.g. immediately after sign-up before onboarding writes it).
  Future<Profile?> fetchOwn(String userId) async {
    final row = await _runner.selectById(userId);
    if (row == null) return null;
    return Profile.fromMap(row);
  }
}
