import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/profile.dart';

/// Columns where the database revokes column-level UPDATE from the
/// `authenticated` role (spec §2.2). The client guards them at the edge so a
/// stray UI handler that tries to flip e.g. `onboarded` surfaces a typed
/// [ForbiddenColumnException] instead of a 403 from Postgrest.
const Set<String> kReadOnlyProfileColumns = <String>{
  'verified_github_username',
  'verified_github_id',
  'verified_at',
  'suspended_at',
  'onboarded',
  'private_mode',
  'public_investor_page',
};

/// Thrown when a caller tries to update a column listed in
/// [kReadOnlyProfileColumns]. The forbidden column name is carried on the
/// exception so the UI can render a developer-friendly hint in debug mode.
class ForbiddenColumnException implements Exception {
  ForbiddenColumnException(this.column);
  final String column;
  @override
  String toString() =>
      'ForbiddenColumnException(column=$column) — use the dedicated RPC.';
}

/// Test-seam abstraction over the slice of `SupabaseClient` that
/// [ProfileService] touches. Concrete adapter binds to the real client; tests
/// inject in-memory fakes via [profileGatewayProvider] / direct construction.
abstract class ProfileGateway {
  /// `profiles.select().eq('id', id).maybeSingle()` — returns null when no row.
  Future<Map<String, dynamic>?> fetchById(String id);

  /// `profiles.update(patch).eq('id', id).select().single()` — returns the
  /// row Postgrest echoes back after the patch is applied.
  Future<Map<String, dynamic>> updateById({
    required String id,
    required Map<String, dynamic> patch,
  });

  /// Postgrest RPC (`rpc(name, params: params)`). Returns whatever Postgrest
  /// echoes back — caller is responsible for narrowing the shape.
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});

  /// `functions.invoke(name, body: body)` for SECURITY DEFINER paths that
  /// run in an edge function (e.g. `delete-account` which also deletes the
  /// `auth.users` row after the wipe).
  Future<FunctionResponse> invokeFunction(String name, {Object? body});
}

/// Production [ProfileGateway] backed by the live Supabase client.
class SupabaseProfileGateway implements ProfileGateway {
  SupabaseProfileGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchById(String id) async {
    return _client.from('profiles').select().eq('id', id).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> updateById({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('profiles')
        .update(patch)
        .eq('id', id)
        .select();
    if (rows.isEmpty) {
      // Should not happen — RLS lets the caller read their own row — but be
      // defensive so a future migration that adds a returning-rows trigger
      // doesn't crash the client with an empty-list cast.
      throw const PostgrestException(
        message: 'update returned no rows',
        code: '42501',
      );
    }
    return rows.first;
  }

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);

  @override
  Future<FunctionResponse> invokeFunction(String name, {Object? body}) =>
      _client.functions.invoke(name, body: body);
}

/// Coordinates Phase-4 profile mutations: fetch own row, patch allowed
/// columns, toggle private mode, export GDPR archive, account deletion.
///
/// Sensitive columns (`verified_*`, `suspended_at`, `onboarded`,
/// `private_mode`, `public_investor_page`) are blocked at the client edge —
/// they round-trip exclusively via SECURITY DEFINER RPCs or the
/// `delete-account` edge function.
class ProfileService {
  ProfileService(this._gateway);
  final ProfileGateway _gateway;

  /// Fetches the caller's own row by id. Returns `null` when no row exists
  /// (the row is materialised lazily after sign-up; spec §5.3 treats the
  /// missing-row case as "not yet onboarded").
  Future<Profile?> fetchOwn(String userId) async {
    try {
      final Map<String, dynamic>? row = await _gateway.fetchById(userId);
      if (row == null) return null;
      return Profile.fromMap(row);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Patches the caller's profile. Throws [ForbiddenColumnException] when
  /// the patch tries to touch a column whose UPDATE is revoked from the
  /// `authenticated` role (spec §2.2). Postgrest errors funnel through
  /// `mapPostgrestError`.
  Future<Profile> updateProfile({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    for (final String key in patch.keys) {
      if (kReadOnlyProfileColumns.contains(key)) {
        throw ForbiddenColumnException(key);
      }
    }
    try {
      final Map<String, dynamic> row =
          await _gateway.updateById(id: userId, patch: patch);
      return Profile.fromMap(row);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Toggles `profiles.private_mode` via the `set_private_mode` SECURITY
  /// DEFINER RPC. The RPC is the ONLY path — column-level UPDATE on
  /// `private_mode` is revoked from the client.
  Future<void> setPrivateMode(bool value) async {
    try {
      await _gateway.rpc(
        'set_private_mode',
        params: <String, dynamic>{'p_value': value},
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Returns the JSON aggregate produced by the `export_my_data` RPC
  /// (spec §3.1). Caller is responsible for serialising + sharing it
  /// (Phase 13 wires the system share-sheet handoff).
  Future<Map<String, dynamic>> exportMyData() async {
    try {
      final Object? raw = await _gateway.rpc('export_my_data');
      if (raw is Map<String, dynamic>) return raw;
      return <String, dynamic>{};
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// GDPR account deletion. Per spec §4.2 + §6.11 we go through the
  /// `delete-account` edge function — never the RPC directly — because the
  /// function admin-deletes the `auth.users` row after the wipe. Caller is
  /// responsible for triggering local sign-out + persisted-store reset
  /// after this resolves.
  Future<void> deleteMyAccount() async {
    final FunctionResponse response =
        await _gateway.invokeFunction('delete-account');
    if (response.status >= 400) {
      throw GenericAppException(
        StateError('delete-account returned ${response.status}: '
            '${response.data}'),
      );
    }
  }
}

/// Wires [ProfileService] to the live Supabase client. Tests override via
/// `profileServiceProvider.overrideWithValue(...)` in
/// [own_profile_provider.dart] (Task 9).
final Provider<ProfileService> profileServiceProvider =
    Provider<ProfileService>((Ref<ProfileService> ref) {
  return ProfileService(
    SupabaseProfileGateway(ref.watch(supabaseClientProvider)),
  );
});
