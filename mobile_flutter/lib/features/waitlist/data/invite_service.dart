import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/invite_code.dart';

/// Test-seam abstraction over the Supabase RPC surface the invite + waitlist
/// feature touches. Mirrors the gateway pattern used by `OpportunitiesService`
/// so tests can fake every RPC without a live Supabase.
abstract class InviteGateway {
  /// Generic RPC dispatch — `join_waitlist`, `redeem_invite`, and
  /// `ensure_invite_codes` all flow through here.
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

/// Live adapter backed by [SupabaseClient].
class SupabaseInviteGateway implements InviteGateway {
  SupabaseInviteGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

/// Thin wrapper over the three invite + waitlist RPCs (migration
/// `20260612030000_invite_waitlist.sql`):
///
/// * `join_waitlist(p_email)`        — idempotent add to the waitlist.
/// * `redeem_invite(p_code)`         — consume an invite code at sign-up.
/// * `ensure_invite_codes(p_count)`  — get/generate the caller's share codes.
///
/// All Postgrest errors are funnelled through [mapPostgrestError] so the UI
/// receives typed [AppException]s (e.g. `ValidationException` carrying the
/// `invite.errors.invalidCode` / `expiredCode` / `exhaustedCode` keys).
class InviteService {
  InviteService(this._gateway);

  final InviteGateway _gateway;

  /// `join_waitlist(p_email)` — idempotent server-side. Validates the email
  /// shape on the server; a malformed email surfaces as a [ValidationException]
  /// carrying the `waitlist.errors.invalidEmail` key.
  Future<void> joinWaitlist(String email) async {
    try {
      await _gateway.rpc(
        'join_waitlist',
        params: <String, dynamic>{'p_email': email},
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `redeem_invite(p_code)` — best-effort consume of an invite code for the
  /// authenticated caller. Idempotent per redeemer. Bad / expired / exhausted
  /// codes surface as a [ValidationException] with a stable i18n key.
  Future<void> redeemInvite(String code) async {
    try {
      await _gateway.rpc(
        'redeem_invite',
        params: <String, dynamic>{'p_code': code},
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `ensure_invite_codes(p_count)` — ensures the caller owns at least
  /// [count] unexpired codes (generating more if needed) and returns the full
  /// set, newest first.
  Future<List<InviteCode>> ensureInviteCodes({int count = 3}) async {
    try {
      final Object? raw = await _gateway.rpc(
        'ensure_invite_codes',
        params: <String, dynamic>{'p_count': count},
      );
      final List<Map<String, dynamic>> rows = _rows(raw);
      return rows.map(InviteCode.fromJson).toList(growable: false);
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Normalises a List-of-maps RPC payload into a typed list.
  static List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw == null) return const <Map<String, dynamic>>[];
    return (raw as List)
        .map((Object? r) => Map<String, dynamic>.from(r! as Map))
        .toList(growable: false);
  }
}

/// Riverpod handle to the configured [InviteService] singleton.
final Provider<InviteService> inviteServiceProvider = Provider<InviteService>((
  Ref<InviteService> ref,
) {
  return InviteService(
    SupabaseInviteGateway(ref.watch(supabaseClientProvider)),
  );
});
