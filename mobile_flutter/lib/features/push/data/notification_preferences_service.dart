import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notification_channel.dart';
import '../domain/notification_kind.dart';
import '../domain/notification_preference.dart';

/// Test seam over the slice of the Supabase API the preferences service
/// touches: a single `select()` against `notification_preferences` and a
/// single `upsert(...)` against the same table. Tests inject a fake; the
/// production adapter wraps a [SupabaseClient].
abstract class NotificationPreferencesGateway {
  /// `SELECT * FROM notification_preferences` (RLS scopes to the caller).
  Future<List<Map<String, dynamic>>> listMyPreferences();

  /// `INSERT ... ON CONFLICT (user_id, kind, channel) DO UPDATE`.
  Future<void> upsertPreference(Map<String, dynamic> row);
}

class SupabaseNotificationPreferencesGateway
    implements NotificationPreferencesGateway {
  SupabaseNotificationPreferencesGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> listMyPreferences() async {
    final dynamic raw = await _client.from('notification_preferences').select();
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .map((Object? r) => Map<String, dynamic>.from(r! as Map))
        .toList(growable: false);
  }

  @override
  Future<void> upsertPreference(Map<String, dynamic> row) async {
    await _client
        .from('notification_preferences')
        .upsert(row, onConflict: 'user_id,kind,channel');
  }
}

/// Service for the spec section 2.17 `notification_preferences` matrix.
/// Phase 13's Settings UI consumes this through `notificationPrefsProvider`.
class NotificationPreferencesService {
  NotificationPreferencesService(this._gateway, {SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final NotificationPreferencesGateway _gateway;
  final SupabaseClient _supabase;

  /// Returns ALL stored rows for the current user. Any (kind, channel)
  /// combo NOT in the result defaults to enabled=true (matches the
  /// `should_notify` default-open semantics).
  Future<List<NotificationPreference>> listMyPreferences() async {
    final List<Map<String, dynamic>> rows = await _gateway.listMyPreferences();
    return rows.map(NotificationPreference.fromJson).toList(growable: false);
  }

  /// UPSERTs a single `(user_id, kind, channel)` row.
  ///
  /// Throws [StateError] when there's no authenticated session - the caller
  /// is responsible for gating the matrix UI behind a sign-in check.
  Future<void> setPreference({
    required NotificationKind kind,
    required NotificationChannel channel,
    required bool enabled,
  }) async {
    final String? uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('setPreference requires an authenticated session');
    }
    await _gateway.upsertPreference(<String, dynamic>{
      'user_id': uid,
      'kind': kind.dbValue,
      'channel': channel.dbValue,
      'enabled': enabled,
    });
  }
}
