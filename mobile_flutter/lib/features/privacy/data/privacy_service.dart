import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/blocked_user.dart';
import '../domain/report_reason.dart';
import '../domain/report_target_type.dart';

/// Test-seam abstraction over the Supabase RPC surface the Privacy feature
/// touches. Mirrors the gateway pattern used by `IntrosService`,
/// `OfficeHoursService`, and `OpportunitiesService` so unit tests can fake
/// every RPC call without spinning up Supabase.
abstract class PrivacyGateway {
  /// Generic RPC dispatch — all four privacy RPCs flow through here.
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

/// Live adapter backed by [SupabaseClient].
class SupabasePrivacyGateway implements PrivacyGateway {
  SupabasePrivacyGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

/// Thin wrapper over the four Privacy RPCs (spec §3.8):
///
///   `block_user`, `unblock_user`, `list_blocked_users`, `report_target`.
///
/// All Postgrest errors are funnelled through [mapPostgrestError] so the UI
/// receives typed [AppException]s — `BlockedException` for `P0001`+`blocked`,
/// `ForbiddenException` for 42501, `ValidationException` for note-length
/// breaches we catch client-side.
class PrivacyService {
  PrivacyService(this._gateway);

  final PrivacyGateway _gateway;

  /// Maximum note length accepted by `report_target` (spec §2.12). The server
  /// applies its own CHECK; we mirror it here to fail fast without a round
  /// trip and give the user a localized error key.
  static const int kReportNoteMaxChars = 1000;

  /// `block_user(p_target uuid)` — places a one-way block from the caller
  /// onto [targetId] and, server-side, auto-declines any active `delivered`
  /// intros between the pair (spec §3.8). Callers should invalidate
  /// `receivedIntrosProvider` / `sentIntrosProvider` after success.
  Future<void> blockUser(String targetId) async {
    try {
      await _gateway.rpc(
        'block_user',
        params: <String, dynamic>{'p_target': targetId},
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `unblock_user(p_target uuid)` — removes the caller's block on
  /// [targetId]. Per spec §17, the spec keeps a forward-intent "blocked
  /// users can never re-request even if you unblock" — that's enforced
  /// downstream in `send_intro`, not here.
  Future<void> unblockUser(String targetId) async {
    try {
      await _gateway.rpc(
        'unblock_user',
        params: <String, dynamic>{'p_target': targetId},
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `list_blocked_users()` — RLS-scoped to the caller, returns
  /// `(blocked_id, handle, name, photo_url, created_at)` rows newest-first.
  Future<List<BlockedUser>> listBlockedUsers() async {
    try {
      final Object? raw = await _gateway.rpc('list_blocked_users');
      if (raw == null) return const <BlockedUser>[];
      final List<Map<String, dynamic>> rows = (raw as List<dynamic>)
          .map((Object? r) => Map<String, dynamic>.from(r! as Map))
          .toList(growable: false);
      return rows.map(BlockedUser.fromJson).toList(growable: false);
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `report_target(p_target_type text, p_target_id uuid, p_reason text,
  ///                p_note text, p_quoted_message_id uuid)`.
  ///
  /// [note] is capped client-side at [kReportNoteMaxChars] chars; longer
  /// inputs throw [ValidationException] *before* hitting the network.
  /// [quotedMessageId] is only meaningful when [targetType] is
  /// `ReportTargetType.message`; the caller is responsible for pre-populating
  /// it from the chat bubble's source message id — this service does not
  /// enforce that invariant so non-chat callers can pass `null` cleanly.
  Future<void> reportTarget({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? note,
    String? quotedMessageId,
  }) async {
    if (note != null && note.length > kReportNoteMaxChars) {
      throw ValidationException('privacy.reportModal.noteTooLong');
    }
    try {
      await _gateway.rpc(
        'report_target',
        params: <String, dynamic>{
          'p_target_type': targetType.wire,
          'p_target_id': targetId,
          'p_reason': reason.wire,
          'p_note': note,
          'p_quoted_message_id': quotedMessageId,
        },
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }
}

/// Riverpod handle to the configured [PrivacyService] singleton.
final Provider<PrivacyService> privacyServiceProvider =
    Provider<PrivacyService>((Ref<PrivacyService> ref) {
  return PrivacyService(
    SupabasePrivacyGateway(ref.watch(supabaseClientProvider)),
  );
});
