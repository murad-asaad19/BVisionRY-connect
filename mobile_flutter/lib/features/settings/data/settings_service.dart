import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';

/// Test seam over the slice of [SupabaseClient] our settings flow touches:
/// RPC calls (`export_my_data`, `set_private_mode`), a direct `update` on
/// `profiles.read_receipts_enabled`, and the password change via the auth
/// admin API. Tests inject a fake; the production adapter wraps the live
/// client.
abstract class SettingsGateway {
  /// `supabase.rpc(name, params)` — returns whatever Postgrest echoes back.
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});

  /// `supabase.from('profiles').update(patch).eq('id', authUserId)`.
  /// Caller is responsible for passing the current user's id.
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> patch,
  });

  /// Returns the currently-signed-in user's id, or `null` when the session
  /// has rolled away.
  String? get currentUserId;

  /// `supabase.auth.updateUser(UserAttributes(password: ...))`.
  Future<UserResponse> updatePassword(String newPassword);
}

/// Production adapter — delegates each method to the live [SupabaseClient].
class SupabaseSettingsGateway implements SettingsGateway {
  SupabaseSettingsGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);

  @override
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    await _client.from('profiles').update(patch).eq('id', userId);
  }

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<UserResponse> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));
}

/// Settings-side mutations the UI calls into. Each method maps a Postgrest
/// or auth error through the typed [AppException] hierarchy so the calling
/// widget can render a localized toast.
///
/// Spec coverage:
/// - `export_my_data` RPC (§3.1) — JSON export pipeline.
/// - `set_private_mode` RPC (§2.2) — column-level UPDATE on `private_mode`
///   is revoked from `authenticated`, so the RPC is the only path.
/// - Direct UPDATE on `profiles.read_receipts_enabled` — column is NOT in
///   the revoke list (§2.2 lines 268-271), so a direct write is allowed.
/// - `set_public_investor_page` — spec §17.2 declares the column revoked
///   from UPDATE but ships no RPC yet. We throw [UnimplementedRpcException]
///   so the UI surfaces a `ComingSoonCard` instead of pretending the write
///   succeeded.
/// - `auth.updateUser(password: ...)` — gated on ≥ 8 chars client-side so
///   we surface [ValidationException] before hitting the server.
class SettingsService {
  SettingsService(this._gateway);
  final SettingsGateway _gateway;

  /// Calls the `export_my_data` RPC and returns the raw JSON aggregate.
  /// Caller is responsible for serialising + sharing (the share-sheet
  /// handoff lives in `ExportDataTile`).
  Future<Map<String, dynamic>> exportMyData() async {
    try {
      final Object? raw = await _gateway.rpc('export_my_data');
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return <String, dynamic>{};
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Toggles `profiles.private_mode` via the SECURITY DEFINER RPC.
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

  /// Direct UPDATE on `profiles.read_receipts_enabled`. The column is NOT
  /// in the §2.2 revoke list, so we don't need an RPC.
  Future<void> setReadReceiptsEnabled(bool value) async {
    final String? uid = _gateway.currentUserId;
    if (uid == null) throw UnauthenticatedException();
    try {
      await _gateway.updateProfile(
        userId: uid,
        patch: <String, dynamic>{'read_receipts_enabled': value},
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// PLANNED SERVER RPC — see spec §17.2 and Phase 13 plan header.
  ///
  /// Until `set_public_investor_page(p_value boolean)` lands server-side,
  /// this throws [UnimplementedRpcException] so the UI surfaces a
  /// coming-soon banner instead of silently failing or pretending the
  /// write succeeded.
  Future<void> setPublicInvestorPage(bool value) async {
    throw UnimplementedRpcException('set_public_investor_page');
  }

  /// Changes the signed-in user's password via Supabase Auth.
  ///
  /// Throws [ValidationException] when the password is shorter than 8
  /// characters; otherwise delegates to `auth.updateUser`. Auth errors are
  /// mapped through [mapAuthError] so the UI receives a typed exception.
  Future<void> changePassword(String newPassword) async {
    if (newPassword.length < 8) {
      throw ValidationException('settings.changePassword.tooShort');
    }
    try {
      await _gateway.updatePassword(newPassword);
    } on AuthException catch (e) {
      throw mapAuthError(e);
    }
  }
}

/// The configured [SettingsService] singleton. Override in tests via
/// `settingsServiceProvider.overrideWithValue(...)`.
final Provider<SettingsService> settingsServiceProvider =
    Provider<SettingsService>((Ref<SettingsService> ref) {
  return SettingsService(
    SupabaseSettingsGateway(ref.watch(supabaseClientProvider)),
  );
});
