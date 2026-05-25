import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/intro.dart';

/// Test-seam abstraction over the Supabase surface the Intros feature
/// touches: the four RPC entry points plus the `intros` table SELECTs
/// used by `listReceivedIntros` / `listSentIntros`.
///
/// Concrete adapter binds to the live [SupabaseClient]; unit tests inject
/// a `mocktail`-driven [Mock] implementation.
abstract class IntrosGateway {
  /// Generic RPC dispatch — `send_intro`, `accept_intro`, `decline_intro`,
  /// `intros_today_count`.
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});

  /// `SELECT * FROM intros WHERE recipient_id = :viewer ORDER BY created_at DESC`.
  /// RLS limits rows to the caller's recipient-side intros automatically.
  Future<List<Map<String, dynamic>>> selectReceivedIntros(String viewerId);

  /// `SELECT * FROM intros WHERE sender_id = :viewer ORDER BY created_at DESC`.
  Future<List<Map<String, dynamic>>> selectSentIntros(String viewerId);
}

class SupabaseIntrosGateway implements IntrosGateway {
  SupabaseIntrosGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);

  @override
  Future<List<Map<String, dynamic>>> selectReceivedIntros(
    String viewerId,
  ) async {
    final rows = await _client
        .from('intros')
        .select()
        .eq('recipient_id', viewerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<List<Map<String, dynamic>>> selectSentIntros(String viewerId) async {
    final rows = await _client
        .from('intros')
        .select()
        .eq('sender_id', viewerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}

/// Provider that exposes the configured [IntrosService] singleton.
final Provider<IntrosService> introsServiceProvider = Provider<IntrosService>((
  Ref<IntrosService> ref,
) {
  return IntrosService(
    SupabaseIntrosGateway(ref.watch(supabaseClientProvider)),
  );
});

/// Thin wrapper over the four intro RPCs and the two list-by-side SELECTs.
///
/// All Postgrest errors are normalised through [mapPostgrestError] so the
/// UI layer always receives typed [AppException]s — in particular the
/// kind-specific [WrongIntroKindException] raised when `accept_intro` is
/// called against a `warm_request` row.
class IntrosService {
  IntrosService(this._gateway);

  final IntrosGateway _gateway;

  /// `send_intro(p_recipient_id, p_note)` returns the inserted row.
  ///
  /// Trims [note] before sending so the server's `char_length(btrim(note))`
  /// check sees exactly what the user typed minus surrounding whitespace.
  Future<Intro> sendIntro({
    required String recipientId,
    required String note,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'send_intro',
        params: <String, dynamic>{
          'p_recipient_id': recipientId,
          'p_note': note.trim(),
        },
      );
      return Intro.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `accept_intro(p_intro_id)` returns the updated row (with
  /// `conversation_id` populated). Raises [WrongIntroKindException] when
  /// called against a `warm_request`.
  Future<Intro> acceptIntro(String introId) async {
    try {
      final raw = await _gateway.rpc(
        'accept_intro',
        params: <String, dynamic>{'p_intro_id': introId},
      );
      return Intro.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `decline_intro(p_intro_id)` returns the updated row (`state =
  /// declined`). For `kind = warm_request` rows the server intentionally
  /// skips stamping `declined_at` so the cooldown isn't poisoned — that
  /// behaviour is server-side, the Flutter caller does nothing special.
  Future<Intro> declineIntro(String introId) async {
    try {
      final raw = await _gateway.rpc(
        'decline_intro',
        params: <String, dynamic>{'p_intro_id': introId},
      );
      return Intro.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `intros_today_count()` returns an integer count of intros the caller
  /// has sent in the current local day. Used to render the gallery's I3
  /// banner when the cap is hit.
  Future<int> introsTodayCount() async {
    try {
      final raw = await _gateway.rpc('intros_today_count');
      return (raw as num).toInt();
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Lists intros the caller has received, newest first. Returns rows from
  /// `public.intros` (no joined profile data — the UI resolves the peer
  /// profile via `profileByIdProvider`).
  Future<List<Intro>> listReceivedIntros({required String viewerId}) async {
    try {
      final rows = await _gateway.selectReceivedIntros(viewerId);
      return rows.map(Intro.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Lists intros the caller has sent, newest first.
  Future<List<Intro>> listSentIntros({required String viewerId}) async {
    try {
      final rows = await _gateway.selectSentIntros(viewerId);
      return rows.map(Intro.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Coerces a single-row RPC response (sometimes returned as a one-element
  /// list, sometimes as a bare map) into a typed `Map<String, dynamic>`.
  Map<String, dynamic> _normaliseRow(Object? raw) {
    if (raw is List && raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }
}
