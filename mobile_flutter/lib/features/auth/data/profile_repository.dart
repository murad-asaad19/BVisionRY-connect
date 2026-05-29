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

  /// Columns fetched for the signed-in user's own profile.
  ///
  /// This is the FULL set the `profiles` table exposes (every column the
  /// [Profile] domain reads that physically exists on the row) — not just the
  /// routing-gate subset. `profileProvider` is the single source of truth for
  /// the own profile, feeding both the auth gate (which only reads `id`,
  /// `onboarded`, `suspended_at`) AND the Profile tab (which renders the hero,
  /// goal, role pills, location, bio and completeness). Selecting the routing
  /// subset alone left the own-profile screen blank in production even though
  /// the row was fully populated. Fetching the extra columns is a single
  /// by-primary-key read, so the gate cost is negligible.
  ///
  /// Role-specific structured fields (`builder_*` / `founder_*` /
  /// `investor_*`) and `last_active_at` are now real columns on `profiles`
  /// (role-detail capture migration), so they are selected here to populate
  /// the profile's `_RoleDetailsCard` and the structured-detail completeness
  /// slot.
  static const String _ownProfileColumns = 'id, handle, name, headline, bio, '
      'roles, primary_role, city, country, goal_type, goal_text, '
      'goal_updated_at, photo_url, onboarded, verified_github_username, '
      'verified_github_id, verified_at, suspended_at, private_mode, '
      'read_receipts_enabled, public_investor_page, created_at, updated_at, '
      'last_active_at, tos_accepted_at, privacy_accepted_at, '
      'builder_discipline, builder_seniority, builder_skills, '
      'builder_open_to, builder_rate_band, founder_stage, founder_sector, '
      'founder_funding, founder_hiring, investor_type, investor_check_size, '
      'investor_sectors, investor_stage';

  @override
  Future<Map<String, dynamic>?> selectById(String id) async {
    final res = await _client
        .from('profiles')
        .select(_ownProfileColumns)
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
