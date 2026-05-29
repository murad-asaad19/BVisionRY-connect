import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/session_provider.dart';

/// Length of the decline cooldown window. Mirrors the server gate in
/// `send_intro` (`coalesce(declined_at, updated_at) > now() - interval
/// '30 days'`, migration 20260607020000_feature_fixes.sql) so the proactive
/// UI state and the authoritative server rejection agree.
const Duration kIntroCooldownWindow = Duration(days: 30);

/// Viewer-side decline-cooldown state for a recipient profile (gallery
/// section I4).
///
/// Encodes whether the current viewer is currently locked out of sending an
/// intro to the recipient (because the recipient declined a prior intro) and,
/// when available, the wall-clock date when the cooldown lifts. The server
/// is the authoritative gate — `intros.send` raises `IntroCooldownException`
/// regardless — but exposing the same state up-front lets the UI render a
/// disabled "Send intro · available {date}" button and a warning banner per
/// the gallery spec (lines 2379–2388).
class IntroCooldownState {
  const IntroCooldownState({this.active = false, this.availableAt});

  /// `true` when the recipient declined an earlier intro from this viewer
  /// and the 30-day cooldown is still in effect.
  final bool active;

  /// UTC instant when the cooldown lifts. Null when the server hasn't
  /// exposed the exact release date — the UI falls back to "available soon"
  /// copy in that case.
  final DateTime? availableAt;
}

/// Resolves the proactive decline-cooldown state for `recipientId` from the
/// viewer's own `intros` rows.
///
/// There is no dedicated cooldown RPC; `send_intro` only enforces the window
/// reactively. We reproduce the same predicate client-side: the most recent
/// `declined` intro this viewer sent to the recipient, with its decline
/// timestamp (or `updated_at` fallback) still inside [kIntroCooldownWindow].
/// RLS (`intros_select_party`) lets the sender read their own rows, so this
/// query is safe and scoped to the viewer's outbound intros only.
///
/// Returns "no cooldown" for an anonymous viewer (no session) and on any
/// read error — the server remains the hard gate, so a soft-state miss only
/// means the proactive banner/disabled-CTA don't show; the send itself is
/// still rejected if a cooldown truly applies.
///
/// NOTE (spec §12): the one-shot-re-request / permanent-lock-on-second-decline
/// rule is not yet modelled server-side (no column tracks "re-requested after
/// a decline"). When that lands, this provider should additionally surface a
/// permanent-lock state. For now the banner copy conveys the rule textually.
final FutureProviderFamily<IntroCooldownState, String> introCooldownProvider =
    FutureProvider.family<IntroCooldownState, String>(
  (Ref<AsyncValue<IntroCooldownState>> ref, String recipientId) async {
    final Session? session = ref.watch(currentSessionProvider);
    final String? viewerId = session?.user.id;
    if (viewerId == null || recipientId.isEmpty) {
      return const IntroCooldownState();
    }

    final SupabaseClient client = ref.watch(supabaseClientProvider);
    try {
      final List<Map<String, dynamic>> rows = await client
          .from('intros')
          .select('declined_at, updated_at')
          .eq('sender_id', viewerId)
          .eq('recipient_id', recipientId)
          .eq('state', 'declined')
          .order('declined_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return const IntroCooldownState();

      final Map<String, dynamic> row = rows.first;
      final DateTime? declinedAt =
          _parseUtc(row['declined_at']) ?? _parseUtc(row['updated_at']);
      if (declinedAt == null) return const IntroCooldownState();

      final DateTime availableAt = declinedAt.add(kIntroCooldownWindow);
      final bool active = availableAt.isAfter(DateTime.now().toUtc());
      return IntroCooldownState(
        active: active,
        availableAt: active ? availableAt : null,
      );
    } catch (_) {
      // Best-effort proactive hint — never block the screen on a read error.
      return const IntroCooldownState();
    }
  },
);

/// Parses a Postgres timestamptz value into a UTC [DateTime], tolerating the
/// `String` shape Supabase returns. Returns null for null/unparseable values.
DateTime? _parseUtc(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final DateTime? parsed = DateTime.tryParse(value);
    return parsed?.toUtc();
  }
  return null;
}
